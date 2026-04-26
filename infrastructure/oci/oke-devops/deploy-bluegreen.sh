#!/usr/bin/env bash
set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

require_env OKE_CLUSTER_ID
require_env OCI_REGION
require_env APP_BASE_URL
require_env APP_NAMESPACE
require_env APP_IMAGE
require_env IMAGE_REGISTRY_ENDPOINT
require_env IMAGE_REGISTRY_USERNAME
require_env IMAGE_REGISTRY_PASSWORD_SECRET_OCID
require_env RUNTIME_DB_URL
require_env RUNTIME_DB_USERNAME
require_env RUNTIME_DB_PASSWORD_SECRET_OCID
require_env POSTGRESQL_DB_SYSTEM_ID

SERVICE_TYPE="${SERVICE_TYPE:-ClusterIP}"
POST_SWITCH_OBSERVATION_SECONDS="${POST_SWITCH_OBSERVATION_SECONDS:-120}"
POST_SWITCH_OBSERVATION_INTERVAL_SECONDS="${POST_SWITCH_OBSERVATION_INTERVAL_SECONDS:-10}"
POST_SWITCH_SMOKE_PATH="${POST_SWITCH_SMOKE_PATH:-/login}"
WORKDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

oci ce cluster create-kubeconfig \
  --cluster-id "$OKE_CLUSTER_ID" \
  --region "$OCI_REGION" \
  --file "$WORKDIR/kubeconfig" \
  --token-version 2.0.0 \
  --kube-endpoint PRIVATE_ENDPOINT \
  --overwrite >/dev/null

export KUBECONFIG="$WORKDIR/kubeconfig"
export APP_HOST="${APP_HOST:-}"
export SERVICE_TYPE

base64_decode() {
  if base64 --help 2>&1 | grep -q -- '--decode'; then
    base64 --decode
    return 0
  fi

  base64 -D
}

read_secret_value() {
  local secret_ocid="$1"
  oci secrets secret-bundle get \
    --secret-id "$secret_ocid" \
    --query 'data."secret-bundle-content".content' \
    --raw-output | base64_decode
}

resolve_runtime_db_ssl_root_cert_base64() {
  if [[ -n "${RUNTIME_DB_SSL_ROOT_CERT_BASE64:-}" ]]; then
    printf '%s' "$RUNTIME_DB_SSL_ROOT_CERT_BASE64"
    return 0
  fi

  OCI_CLI_REGION="$OCI_REGION" oci psql connection-details get \
    --db-system-id "$POSTGRESQL_DB_SYSTEM_ID" \
    --query 'data."ca-certificate"' \
    --raw-output | base64 | tr -d '\n'
}

current_slot="$(kubectl get service wortwerk-active \
  -n "$APP_NAMESPACE" \
  -o go-template='{{index .spec.selector "app.kubernetes.io/slot"}}' 2>/dev/null || true)"

if [[ "$current_slot" == "blue" ]]; then
  PREVIOUS_SLOT="blue"
  TARGET_SLOT="green"
elif [[ "$current_slot" == "green" ]]; then
  PREVIOUS_SLOT="green"
  TARGET_SLOT="blue"
else
  PREVIOUS_SLOT=""
  TARGET_SLOT="blue"
fi

export APP_SLOT="$TARGET_SLOT"
export ACTIVE_SLOT="$TARGET_SLOT"

render() {
  local source="$1"
  local target="$2"
  envsubst < "$source" > "$target"
}

apply_active_service() {
  local slot="$1"
  ACTIVE_SLOT="$slot"
  export ACTIVE_SLOT
  render infrastructure/oci/oke-runtime/manifests/service.yaml.tpl "$WORKDIR/service.yaml"
  kubectl apply -f "$WORKDIR/service.yaml"
}

stop_slot() {
  local slot="$1"
  if [[ -n "$slot" ]]; then
    kubectl delete deployment "wortwerk-$slot" -n "$APP_NAMESPACE" --ignore-not-found
  fi
}

rollback_after_failed_observation() {
  local failed_slot="$1"
  local previous_slot="$2"

  if [[ -n "$previous_slot" ]]; then
    echo "Post-switch observation failed; rolling traffic back to slot: $previous_slot" >&2
    apply_active_service "$previous_slot"
  else
    echo "Post-switch observation failed and no previous slot exists for rollback." >&2
  fi

  stop_slot "$failed_slot"
}

observe_public_endpoint() {
  local deadline
  local check_url

  deadline="$(($(date +%s) + POST_SWITCH_OBSERVATION_SECONDS))"
  check_url="${APP_BASE_URL%/}${POST_SWITCH_SMOKE_PATH}"

  while [[ "$(date +%s)" -lt "$deadline" ]]; do
    if ! curl -fsS "$check_url" >/dev/null; then
      return 1
    fi

    sleep "$POST_SWITCH_OBSERVATION_INTERVAL_SECONDS"
  done
}

render infrastructure/oci/oke-runtime/manifests/namespace.yaml.tpl "$WORKDIR/namespace.yaml"
render infrastructure/oci/oke-runtime/manifests/deployment.yaml.tpl "$WORKDIR/deployment.yaml"

kubectl apply -f "$WORKDIR/namespace.yaml"

IMAGE_REGISTRY_PASSWORD="$(read_secret_value "$IMAGE_REGISTRY_PASSWORD_SECRET_OCID")"
RUNTIME_DB_PASSWORD="$(read_secret_value "$RUNTIME_DB_PASSWORD_SECRET_OCID")"
RUNTIME_DB_SSL_ROOT_CERT_BASE64="$(resolve_runtime_db_ssl_root_cert_base64)"

kubectl create secret docker-registry wortwerk-registry \
  --namespace "$APP_NAMESPACE" \
  --docker-server "$IMAGE_REGISTRY_ENDPOINT" \
  --docker-username "$IMAGE_REGISTRY_USERNAME" \
  --docker-password "$IMAGE_REGISTRY_PASSWORD" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

kubectl create secret generic wortwerk-runtime \
  --namespace "$APP_NAMESPACE" \
  --from-literal=WORTWERK_DB_URL="$RUNTIME_DB_URL" \
  --from-literal=WORTWERK_DB_USERNAME="$RUNTIME_DB_USERNAME" \
  --from-literal=WORTWERK_DB_PASSWORD="$RUNTIME_DB_PASSWORD" \
  --from-literal=WORTWERK_DB_SSL_ROOT_CERT_BASE64="$RUNTIME_DB_SSL_ROOT_CERT_BASE64" \
  --from-literal=SERVER_PORT=8080 \
  --from-literal=MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info \
  --from-literal=MANAGEMENT_ENDPOINT_HEALTH_PROBES_ENABLED=true \
  --dry-run=client \
  -o yaml | kubectl apply -f -

kubectl apply -f "$WORKDIR/deployment.yaml"

kubectl rollout status "deployment/wortwerk-$TARGET_SLOT" -n "$APP_NAMESPACE" --timeout=10m
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/name=wortwerk,app.kubernetes.io/slot=$TARGET_SLOT" \
  -n "$APP_NAMESPACE" \
  --timeout=10m

apply_active_service "$TARGET_SLOT"

if [[ "${USE_NGINX_INGRESS:-false}" == "true" ]]; then
  require_env APP_HOST
  render infrastructure/oci/oke-runtime/manifests/ingress.yaml.tpl "$WORKDIR/ingress.yaml"
  kubectl apply -f "$WORKDIR/ingress.yaml"
fi

if ! observe_public_endpoint; then
  rollback_after_failed_observation "$TARGET_SLOT" "$PREVIOUS_SLOT"
  exit 1
fi

stop_slot "$PREVIOUS_SLOT"
