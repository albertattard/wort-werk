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

require_command oci
require_command helm
require_command kubectl

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
OCI_LB_SUBNET_ID="${OCI_LB_SUBNET_ID:-}"
OCI_LB_MIN_BANDWIDTH="${OCI_LB_MIN_BANDWIDTH:-10}"
OCI_LB_MAX_BANDWIDTH="${OCI_LB_MAX_BANDWIDTH:-10}"
KUBECONFIG_SERVER_OVERRIDE="${KUBECONFIG_SERVER_OVERRIDE:-}"
KUBECONFIG_TLS_SERVER_NAME_OVERRIDE="${KUBECONFIG_TLS_SERVER_NAME_OVERRIDE:-}"

oci ce cluster create-kubeconfig \
  --cluster-id "$OKE_CLUSTER_ID" \
  --region "$OCI_REGION" \
  --file "$WORKDIR/kubeconfig" \
  --token-version 2.0.0 \
  --kube-endpoint PRIVATE_ENDPOINT \
  --overwrite >/dev/null

export KUBECONFIG="$WORKDIR/kubeconfig"

if [[ -n "$KUBECONFIG_SERVER_OVERRIDE" ]]; then
  cluster_name="$(kubectl config view -o jsonpath='{.clusters[0].name}')"
  kubectl config set-cluster "$cluster_name" --server="$KUBECONFIG_SERVER_OVERRIDE" >/dev/null

  if [[ -n "$KUBECONFIG_TLS_SERVER_NAME_OVERRIDE" ]]; then
    kubectl config set-cluster "$cluster_name" --tls-server-name="$KUBECONFIG_TLS_SERVER_NAME_OVERRIDE" >/dev/null
  fi
fi

kubectl create namespace "$INGRESS_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo update >/dev/null

helm_args=(
  upgrade --install ingress-nginx ingress-nginx/ingress-nginx
  --namespace "$INGRESS_NAMESPACE"
  --set controller.service.type=LoadBalancer
  --set controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape=flexible
  --set controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape-flex-min="$OCI_LB_MIN_BANDWIDTH"
  --set controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-shape-flex-max="$OCI_LB_MAX_BANDWIDTH"
)

if [[ -n "$OCI_LB_SUBNET_ID" ]]; then
  helm_args+=(
    --set controller.service.annotations.service\\.beta\\.kubernetes\\.io/oci-load-balancer-subnet1="$OCI_LB_SUBNET_ID"
  )
fi

helm "${helm_args[@]}" >/dev/null
