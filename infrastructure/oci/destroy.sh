#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUNDATION_DIR="${SCRIPT_DIR}/foundation"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
MODE="${1:-all}"

if [[ "${MODE}" != "all" && "${MODE}" != "foundation" && "${MODE}" != "runtime" ]]; then
  echo "Usage: $0 [all|foundation|runtime]" >&2
  exit 1
fi

write_runtime_foundation_vars_if_possible() {
  if terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid >/dev/null 2>&1; then
    local region
    local tenancy_ocid
    local compartment_ocid
    local subnet_id
    local nsg_id
    local load_balancer_nsg_id
    local load_balancer_public_ip_id
    local load_balancer_public_ip
    local image_repository
    local image_registry_endpoint
    local app_port
    local lb_listener_port
    local load_balancer_min_bandwidth_mbps
    local load_balancer_max_bandwidth_mbps

    region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw region)"
    tenancy_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw tenancy_ocid)"
    compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
    subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw subnet_id)"
    nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw nsg_id)"
    load_balancer_nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_nsg_id)"
    load_balancer_public_ip_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip_id)"
    load_balancer_public_ip="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip)"
    image_repository="$(terraform -chdir="${FOUNDATION_DIR}" output -raw image_repository)"
    image_registry_endpoint="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_registry)"
    app_port="$(terraform -chdir="${FOUNDATION_DIR}" output -raw app_port)"
    lb_listener_port="$(terraform -chdir="${FOUNDATION_DIR}" output -raw lb_listener_port)"
    load_balancer_min_bandwidth_mbps="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_min_bandwidth_mbps)"
    load_balancer_max_bandwidth_mbps="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_max_bandwidth_mbps)"

    cat > "${RUNTIME_DIR}/foundation.auto.tfvars" <<EOF
region = "${region}"
tenancy_ocid = "${tenancy_ocid}"
compartment_ocid = "${compartment_ocid}"
subnet_id        = "${subnet_id}"
nsg_id           = "${nsg_id}"
load_balancer_nsg_id = "${load_balancer_nsg_id}"
load_balancer_public_ip_id = "${load_balancer_public_ip_id}"
load_balancer_public_ip = "${load_balancer_public_ip}"
image_repository = "${image_repository}"
image_registry_endpoint = "${image_registry_endpoint}"
app_port = ${app_port}
lb_listener_port = ${lb_listener_port}
load_balancer_min_bandwidth_mbps = ${load_balancer_min_bandwidth_mbps}
load_balancer_max_bandwidth_mbps = ${load_balancer_max_bandwidth_mbps}
EOF
  fi
}

destroy_runtime() {
  write_runtime_foundation_vars_if_possible
  terraform -chdir="${RUNTIME_DIR}" init -upgrade
  terraform -chdir="${RUNTIME_DIR}" apply -auto-approve -destroy -input=false
}

destroy_foundation() {
  terraform -chdir="${FOUNDATION_DIR}" init -upgrade
  terraform -chdir="${FOUNDATION_DIR}" apply -auto-approve -destroy -input=false
}

case "${MODE}" in
  foundation)
    destroy_foundation
    ;;
  runtime)
    destroy_runtime
    ;;
  all)
    destroy_runtime
    destroy_foundation
    ;;
esac
