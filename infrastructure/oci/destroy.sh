#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUNDATION_DIR="${SCRIPT_DIR}/foundation"
DATA_DIR="${SCRIPT_DIR}/data"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
MODE="${1:-all}"

if [[ "${MODE}" != "all" && "${MODE}" != "foundation" && "${MODE}" != "data" && "${MODE}" != "runtime" ]]; then
  echo "Usage: $0 [all|foundation|data|runtime]" >&2
  exit 1
fi

write_data_foundation_vars_if_possible() {
  if terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid >/dev/null 2>&1; then
    local region
    local home_region
    local compartment_ocid
    local database_subnet_id
    local database_nsg_id
    local runtime_dynamic_group_name

    region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw region)"
    home_region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw home_region)"
    compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
    database_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw database_subnet_id)"
    database_nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw database_nsg_id)"
    runtime_dynamic_group_name="$(terraform -chdir="${FOUNDATION_DIR}" output -raw runtime_dynamic_group_name)"

    cat > "${DATA_DIR}/foundation.auto.tfvars" <<EOFVARS
region = "${region}"
home_region = "${home_region}"
compartment_ocid = "${compartment_ocid}"
database_subnet_id = "${database_subnet_id}"
database_nsg_id = "${database_nsg_id}"
runtime_dynamic_group_name = "${runtime_dynamic_group_name}"
EOFVARS
  fi
}

write_runtime_stack_vars_if_possible() {
  if terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid >/dev/null 2>&1 && terraform -chdir="${DATA_DIR}" output -raw runtime_db_url >/dev/null 2>&1; then
    local region
    local tenancy_ocid
    local compartment_ocid
    local runtime_subnet_id
    local load_balancer_subnet_id
    local nsg_id
    local load_balancer_nsg_id
    local load_balancer_public_ip_id
    local load_balancer_public_ip
    local image_repository
    local image_registry_endpoint
    local app_port
    local management_port
    local lb_listener_port
    local https_listener_port
    local load_balancer_min_bandwidth_mbps
    local load_balancer_max_bandwidth_mbps
    local runtime_db_url
    local runtime_db_username
    local runtime_db_password_secret_ocid
    local runtime_db_ssl_root_cert_base64

    region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw region)"
    tenancy_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw tenancy_ocid)"
    compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
    runtime_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw runtime_subnet_id)"
    load_balancer_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_subnet_id)"
    nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw nsg_id)"
    load_balancer_nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_nsg_id)"
    load_balancer_public_ip_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip_id)"
    load_balancer_public_ip="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip)"
    image_repository="$(terraform -chdir="${FOUNDATION_DIR}" output -raw image_repository)"
    image_registry_endpoint="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_registry)"
    app_port="$(terraform -chdir="${FOUNDATION_DIR}" output -raw app_port)"
    management_port="$(terraform -chdir="${FOUNDATION_DIR}" output -raw management_port)"
    lb_listener_port="$(terraform -chdir="${FOUNDATION_DIR}" output -raw lb_listener_port)"
    https_listener_port="$(terraform -chdir="${FOUNDATION_DIR}" output -raw https_listener_port)"
    load_balancer_min_bandwidth_mbps="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_min_bandwidth_mbps)"
    load_balancer_max_bandwidth_mbps="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_max_bandwidth_mbps)"
    runtime_db_url="$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_url)"
    runtime_db_username="$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_username)"
    runtime_db_password_secret_ocid="$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_password_secret_ocid)"
    runtime_db_ssl_root_cert_base64="$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_ssl_root_cert_base64)"

    cat > "${RUNTIME_DIR}/foundation.auto.tfvars" <<EOFVARS
region = "${region}"
tenancy_ocid = "${tenancy_ocid}"
compartment_ocid = "${compartment_ocid}"
runtime_subnet_id = "${runtime_subnet_id}"
load_balancer_subnet_id = "${load_balancer_subnet_id}"
nsg_id = "${nsg_id}"
load_balancer_nsg_id = "${load_balancer_nsg_id}"
load_balancer_public_ip_id = "${load_balancer_public_ip_id}"
load_balancer_public_ip = "${load_balancer_public_ip}"
runtime_db_url = "${runtime_db_url}"
runtime_db_username = "${runtime_db_username}"
runtime_db_password_secret_ocid = "${runtime_db_password_secret_ocid}"
runtime_db_ssl_root_cert_base64 = "${runtime_db_ssl_root_cert_base64}"
image_repository = "${image_repository}"
image_registry_endpoint = "${image_registry_endpoint}"
app_port = ${app_port}
management_port = ${management_port}
lb_listener_port = ${lb_listener_port}
https_listener_port = ${https_listener_port}
load_balancer_min_bandwidth_mbps = ${load_balancer_min_bandwidth_mbps}
load_balancer_max_bandwidth_mbps = ${load_balancer_max_bandwidth_mbps}
EOFVARS
  fi
}

destroy_runtime() {
  write_runtime_stack_vars_if_possible
  terraform -chdir="${RUNTIME_DIR}" init -upgrade
  terraform -chdir="${RUNTIME_DIR}" apply -auto-approve -destroy -input=false
}

destroy_data() {
  write_data_foundation_vars_if_possible
  terraform -chdir="${DATA_DIR}" init -upgrade
  terraform -chdir="${DATA_DIR}" apply -auto-approve -destroy -input=false
}

destroy_foundation() {
  terraform -chdir="${FOUNDATION_DIR}" init -upgrade
  terraform -chdir="${FOUNDATION_DIR}" apply -auto-approve -destroy -input=false
}

case "${MODE}" in
  foundation)
    destroy_foundation
    ;;
  data)
    destroy_data
    ;;
  runtime)
    destroy_runtime
    ;;
  all)
    destroy_runtime
    destroy_data
    destroy_foundation
    ;;
esac
