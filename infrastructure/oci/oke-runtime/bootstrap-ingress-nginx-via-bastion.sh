#!/usr/bin/env bash
set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_env OKE_CLUSTER_ID
require_env OCI_REGION
require_env OCI_BASTION_ID
require_env BASTION_SSH_PUBLIC_KEY_FILE
require_env BASTION_SSH_PRIVATE_KEY_FILE

require_command oci
require_command ssh
require_command nc

if [[ ! -f "$BASTION_SSH_PUBLIC_KEY_FILE" ]]; then
  echo "Missing SSH public key file: $BASTION_SSH_PUBLIC_KEY_FILE" >&2
  exit 1
fi

if [[ ! -f "$BASTION_SSH_PRIVATE_KEY_FILE" ]]; then
  echo "Missing SSH private key file: $BASTION_SSH_PRIVATE_KEY_FILE" >&2
  exit 1
fi

SESSION_TTL="${BASTION_SESSION_TTL:-10800}"
LOCAL_FORWARD_PORT="${LOCAL_FORWARD_PORT:-16443}"
DISPLAY_NAME="${DISPLAY_NAME:-oke-api-$(date +%Y%m%d%H%M%S)}"
OCI_PROFILE_ARG=()

if [[ -n "${OCI_PROFILE:-}" ]]; then
  OCI_PROFILE_ARG+=(--profile "$OCI_PROFILE")
fi

cluster_private_endpoint="$(
  oci "${OCI_PROFILE_ARG[@]}" ce cluster get \
    --cluster-id "$OKE_CLUSTER_ID" \
    --region "$OCI_REGION" \
    --query 'data.endpoints."private-endpoint"' \
    --raw-output
)"

cluster_vcn_hostname_endpoint="$(
  oci "${OCI_PROFILE_ARG[@]}" ce cluster get \
    --cluster-id "$OKE_CLUSTER_ID" \
    --region "$OCI_REGION" \
    --query 'data.endpoints."vcn-hostname-endpoint"' \
    --raw-output
)"

cluster_private_ip="${cluster_private_endpoint%%:*}"
cluster_private_port="${cluster_private_endpoint##*:}"
cluster_tls_server_name="${cluster_vcn_hostname_endpoint%%:*}"

if [[ -z "$cluster_private_ip" || -z "$cluster_private_port" || -z "$cluster_tls_server_name" ]]; then
  echo "Unable to resolve the cluster private endpoint details." >&2
  exit 1
fi

session_id="$(
  oci "${OCI_PROFILE_ARG[@]}" bastion session create-port-forwarding \
    --bastion-id "$OCI_BASTION_ID" \
    --display-name "$DISPLAY_NAME" \
    --key-type PUB \
    --ssh-public-key-file "$BASTION_SSH_PUBLIC_KEY_FILE" \
    --session-ttl "$SESSION_TTL" \
    --target-private-ip "$cluster_private_ip" \
    --target-port "$cluster_private_port" \
    --wait-for-state SUCCEEDED \
    --query 'data.id' \
    --raw-output
)"

cleanup() {
  if [[ -n "${ssh_pid:-}" ]]; then
    kill "$ssh_pid" >/dev/null 2>&1 || true
    wait "$ssh_pid" 2>/dev/null || true
  fi

  if [[ -n "${session_id:-}" ]]; then
    oci "${OCI_PROFILE_ARG[@]}" bastion session delete \
      --session-id "$session_id" \
      --force >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

ssh -i "$BASTION_SSH_PRIVATE_KEY_FILE" \
  -o ExitOnForwardFailure=yes \
  -o IdentitiesOnly=yes \
  -o ServerAliveInterval=60 \
  -o ServerAliveCountMax=3 \
  -o StrictHostKeyChecking=accept-new \
  -N \
  -L "${LOCAL_FORWARD_PORT}:${cluster_private_ip}:${cluster_private_port}" \
  -p 22 \
  "${session_id}@host.bastion.${OCI_REGION}.oci.oraclecloud.com" &
ssh_pid=$!

for _ in $(seq 1 20); do
  if nc -z 127.0.0.1 "$LOCAL_FORWARD_PORT" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! nc -z 127.0.0.1 "$LOCAL_FORWARD_PORT" >/dev/null 2>&1; then
  echo "The bastion tunnel did not become ready on localhost:${LOCAL_FORWARD_PORT}." >&2
  exit 1
fi

export KUBECONFIG_SERVER_OVERRIDE="https://127.0.0.1:${LOCAL_FORWARD_PORT}"
export KUBECONFIG_TLS_SERVER_NAME_OVERRIDE="$cluster_tls_server_name"

exec ./infrastructure/oci/oke-runtime/bootstrap-ingress-nginx.sh
