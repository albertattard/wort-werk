#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FOUNDATION_DIR="${SCRIPT_DIR}/foundation"
DATA_DIR="${SCRIPT_DIR}/data"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
DEVOPS_DIR="${SCRIPT_DIR}/devops"
MODE="${1:-all}"
BOOTSTRAP_RUNTIME_DB_ROLE_SCRIPT="${DATA_DIR}/bootstrap-runtime-db-role.sh"
RUNTIME_STATE_KEY="runtime/terraform.tfstate"

if [[ "${MODE}" != "all" && "${MODE}" != "foundation" && "${MODE}" != "devops" && "${MODE}" != "data" && "${MODE}" != "db-role" && "${MODE}" != "runtime" ]]; then
  echo "Usage: $0 [all|foundation|devops|data|db-role|runtime]" >&2
  echo "Normal production releases must run through ./infrastructure/oci/devops/run-release.sh." >&2
  exit 1
fi

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required command: ${cmd}" >&2
    exit 1
  fi
}

require_var() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required environment variable: ${var_name}" >&2
    exit 1
  fi
}

read_tfvars_string() {
  local file="$1"
  local key="$2"
  if [[ ! -f "${file}" ]]; then
    return 0
  fi

  awk -F= -v key="${key}" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit 0
    }
  ' "${file}"
}

escape_tfvars_string() {
  local raw="$1"
  raw="${raw//\\/\\\\}"
  raw="${raw//\"/\\\"}"
  printf '%s' "${raw}"
}

upsert_tfvars_string() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped
  local tmp
  escaped="$(escape_tfvars_string "${value}")"
  tmp="$(mktemp)"

  if [[ -f "${file}" ]]; then
    awk -v key="${key}" -v val="${escaped}" '
      BEGIN { found = 0 }
      $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        print key " = \"" val "\""
        found = 1
        next
      }
      { print }
      END {
        if (!found) {
          print key " = \"" val "\""
        }
      }
    ' "${file}" > "${tmp}"
  else
    printf '%s = "%s"\n' "${key}" "${escaped}" > "${tmp}"
  fi

  mv "${tmp}" "${file}"
}

resolve_output_or_env() {
  local env_name="$1"
  local dir="$2"
  local output_name="$3"
  local value="${!env_name:-}"

  if [[ -n "${value}" ]]; then
    printf '%s' "${value}"
    return 0
  fi

  terraform -chdir="${dir}" output -raw "${output_name}"
}

resolve_runtime_image_tag() {
  local existing_tag
  local deployed_image_url
  local release_vars_file="${RUNTIME_DIR}/release.auto.tfvars"

  if [[ -n "${IMAGE_TAG:-}" ]]; then
    printf '%s' "${IMAGE_TAG}"
    return 0
  fi

  existing_tag="$(read_tfvars_string "${release_vars_file}" "image_tag")"
  if [[ -n "${existing_tag}" ]]; then
    printf '%s' "${existing_tag}"
    return 0
  fi

  deployed_image_url="$(terraform -chdir="${RUNTIME_DIR}" output -raw deployed_image_url 2>/dev/null || true)"
  if [[ -n "${deployed_image_url}" && "${deployed_image_url}" == *:* ]]; then
    printf '%s' "${deployed_image_url##*:}"
    return 0
  fi

  echo "Missing image_tag for runtime apply. Set IMAGE_TAG or ensure runtime state has deployed_image_url." >&2
  exit 1
}

apply_foundation() {
  terraform -chdir="${FOUNDATION_DIR}" init -upgrade
  terraform -chdir="${FOUNDATION_DIR}" fmt
  terraform -chdir="${FOUNDATION_DIR}" apply -auto-approve -input=false
}

write_devops_stack_vars() {
  local region
  local home_region
  local tenancy_ocid
  local compartment_ocid
  local devops_subnet_id
  local devops_nsg_id
  local devops_dynamic_group_name
  local image_repository
  local image_registry_endpoint
  local image_registry_username
  local image_registry_password_secret_ocid
  local runtime_state_bucket_name
  local runtime_subnet_id
  local load_balancer_subnet_id
  local nsg_id
  local load_balancer_nsg_id
  local load_balancer_public_ip_id
  local load_balancer_public_ip
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
  local postgresql_admin_username
  local postgresql_admin_password_secret_ocid
  local postgresql_host
  local postgresql_port
  local postgresql_database_name

  region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw region)"
  home_region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw home_region)"
  tenancy_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw tenancy_ocid)"
  compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
  devops_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw devops_subnet_id)"
  devops_nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw devops_nsg_id)"
  devops_dynamic_group_name="$(terraform -chdir="${FOUNDATION_DIR}" output -raw devops_dynamic_group_name)"
  image_repository="$(terraform -chdir="${FOUNDATION_DIR}" output -raw image_repository)"
  image_registry_endpoint="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_registry)"
  runtime_state_bucket_name="$(terraform -chdir="${FOUNDATION_DIR}" output -raw terraform_state_bucket_name)"
  runtime_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw runtime_subnet_id)"
  load_balancer_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_subnet_id)"
  nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw nsg_id)"
  load_balancer_nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_nsg_id)"
  load_balancer_public_ip_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip_id)"
  load_balancer_public_ip="$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip)"
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
  postgresql_admin_username="$(terraform -chdir="${DATA_DIR}" output -raw postgresql_admin_username)"
  postgresql_admin_password_secret_ocid="$(terraform -chdir="${DATA_DIR}" output -raw postgresql_admin_password_secret_ocid)"
  postgresql_host="$(terraform -chdir="${DATA_DIR}" output -raw postgresql_fqdn)"
  postgresql_port="$(terraform -chdir="${DATA_DIR}" output -raw postgresql_port)"
  postgresql_database_name="$(terraform -chdir="${DATA_DIR}" output -raw postgresql_database_name)"

  image_registry_username="${IMAGE_REGISTRY_USERNAME:-$(read_tfvars_string "${DEVOPS_DIR}/terraform.tfvars" "image_registry_username")}"
  image_registry_password_secret_ocid="${IMAGE_REGISTRY_PASSWORD_SECRET_OCID:-$(read_tfvars_string "${DEVOPS_DIR}/terraform.tfvars" "image_registry_password_secret_ocid")}"

  require_var image_registry_username
  require_var image_registry_password_secret_ocid

  cat > "${DEVOPS_DIR}/foundation.auto.tfvars" <<DEVOPSEOF
region = "${region}"
region_runtime = "${region}"
home_region = "${home_region}"
tenancy_ocid = "${tenancy_ocid}"
compartment_ocid = "${compartment_ocid}"
devops_subnet_id = "${devops_subnet_id}"
devops_nsg_id = "${devops_nsg_id}"
devops_dynamic_group_name = "${devops_dynamic_group_name}"
image_repository = "${image_repository}"
image_registry_endpoint = "${image_registry_endpoint}"
image_registry_username = "${image_registry_username}"
image_registry_password_secret_ocid = "${image_registry_password_secret_ocid}"
runtime_state_bucket_name = "${runtime_state_bucket_name}"
runtime_subnet_id = "${runtime_subnet_id}"
load_balancer_subnet_id = "${load_balancer_subnet_id}"
nsg_id = "${nsg_id}"
load_balancer_nsg_id = "${load_balancer_nsg_id}"
load_balancer_public_ip_id = "${load_balancer_public_ip_id}"
load_balancer_public_ip = "${load_balancer_public_ip}"
app_port = ${app_port}
management_port = ${management_port}
lb_listener_port = ${lb_listener_port}
https_listener_port = ${https_listener_port}
load_balancer_min_bandwidth_mbps = ${load_balancer_min_bandwidth_mbps}
load_balancer_max_bandwidth_mbps = ${load_balancer_max_bandwidth_mbps}
runtime_db_url = "${runtime_db_url}"
runtime_db_username = "${runtime_db_username}"
runtime_db_password_secret_ocid = "${runtime_db_password_secret_ocid}"
runtime_db_ssl_root_cert_base64 = "${runtime_db_ssl_root_cert_base64}"
postgresql_admin_username = "${postgresql_admin_username}"
postgresql_admin_password_secret_ocid = "${postgresql_admin_password_secret_ocid}"
postgresql_host = "${postgresql_host}"
postgresql_port = "${postgresql_port}"
postgresql_database_name = "${postgresql_database_name}"
DEVOPSEOF
}

apply_devops() {
  terraform -chdir="${DEVOPS_DIR}" init -upgrade
  write_devops_stack_vars
  terraform -chdir="${DEVOPS_DIR}" fmt
  terraform -chdir="${DEVOPS_DIR}" apply -auto-approve -input=false
}

write_data_foundation_vars() {
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

  cat > "${DATA_DIR}/foundation.auto.tfvars" <<DATAEOF
region = "${region}"
home_region = "${home_region}"
compartment_ocid = "${compartment_ocid}"
database_subnet_id = "${database_subnet_id}"
database_nsg_id = "${database_nsg_id}"
runtime_dynamic_group_name = "${runtime_dynamic_group_name}"
DATAEOF
}

apply_data() {
  terraform -chdir="${DATA_DIR}" init -upgrade
  write_data_foundation_vars
  terraform -chdir="${DATA_DIR}" fmt
  terraform -chdir="${DATA_DIR}" apply -auto-approve -input=false
}

bootstrap_runtime_db_role() {
  require_command "${BOOTSTRAP_RUNTIME_DB_ROLE_SCRIPT}"
  "${BOOTSTRAP_RUNTIME_DB_ROLE_SCRIPT}"
}

write_runtime_stack_vars() {
  local region
  local tenancy_ocid
  local compartment_ocid
  local runtime_subnet_id
  local load_balancer_subnet_id
  local nsg_id
  local load_balancer_nsg_id
  local load_balancer_public_ip_id
  local load_balancer_public_ip
  local runtime_db_url
  local runtime_db_username
  local runtime_db_password_secret_ocid
  local runtime_db_ssl_root_cert_base64
  local image_repository
  local image_registry_endpoint
  local app_port
  local management_port
  local lb_listener_port
  local https_listener_port
  local load_balancer_min_bandwidth_mbps
  local load_balancer_max_bandwidth_mbps

  region="$(resolve_output_or_env REGION "${FOUNDATION_DIR}" region)"
  tenancy_ocid="$(resolve_output_or_env TENANCY_OCID "${FOUNDATION_DIR}" tenancy_ocid)"
  compartment_ocid="$(resolve_output_or_env COMPARTMENT_OCID "${FOUNDATION_DIR}" compartment_ocid)"
  runtime_subnet_id="$(resolve_output_or_env RUNTIME_SUBNET_ID "${FOUNDATION_DIR}" runtime_subnet_id)"
  load_balancer_subnet_id="$(resolve_output_or_env LOAD_BALANCER_SUBNET_ID "${FOUNDATION_DIR}" load_balancer_subnet_id)"
  nsg_id="$(resolve_output_or_env NSG_ID "${FOUNDATION_DIR}" nsg_id)"
  load_balancer_nsg_id="$(resolve_output_or_env LOAD_BALANCER_NSG_ID "${FOUNDATION_DIR}" load_balancer_nsg_id)"
  load_balancer_public_ip_id="$(resolve_output_or_env LOAD_BALANCER_PUBLIC_IP_ID "${FOUNDATION_DIR}" load_balancer_public_ip_id)"
  load_balancer_public_ip="$(resolve_output_or_env LOAD_BALANCER_PUBLIC_IP "${FOUNDATION_DIR}" load_balancer_public_ip)"
  image_repository="$(resolve_output_or_env IMAGE_REPOSITORY "${FOUNDATION_DIR}" image_repository)"
  image_registry_endpoint="$(resolve_output_or_env IMAGE_REGISTRY_ENDPOINT "${FOUNDATION_DIR}" ocir_registry)"
  app_port="$(resolve_output_or_env APP_PORT "${FOUNDATION_DIR}" app_port)"
  management_port="$(resolve_output_or_env MANAGEMENT_PORT "${FOUNDATION_DIR}" management_port)"
  lb_listener_port="$(resolve_output_or_env LB_LISTENER_PORT "${FOUNDATION_DIR}" lb_listener_port)"
  https_listener_port="$(resolve_output_or_env HTTPS_LISTENER_PORT "${FOUNDATION_DIR}" https_listener_port)"
  load_balancer_min_bandwidth_mbps="$(resolve_output_or_env LOAD_BALANCER_MIN_BANDWIDTH_MBPS "${FOUNDATION_DIR}" load_balancer_min_bandwidth_mbps)"
  load_balancer_max_bandwidth_mbps="$(resolve_output_or_env LOAD_BALANCER_MAX_BANDWIDTH_MBPS "${FOUNDATION_DIR}" load_balancer_max_bandwidth_mbps)"

  runtime_db_url="$(resolve_output_or_env RUNTIME_DB_URL "${DATA_DIR}" runtime_db_url)"
  runtime_db_username="$(resolve_output_or_env RUNTIME_DB_USERNAME "${DATA_DIR}" runtime_db_username)"
  runtime_db_password_secret_ocid="$(resolve_output_or_env RUNTIME_DB_PASSWORD_SECRET_OCID "${DATA_DIR}" runtime_db_password_secret_ocid)"
  runtime_db_ssl_root_cert_base64="$(resolve_output_or_env RUNTIME_DB_SSL_ROOT_CERT_BASE64 "${DATA_DIR}" runtime_db_ssl_root_cert_base64)"

  cat > "${RUNTIME_DIR}/foundation.auto.tfvars" <<RUNTIMEEOF
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
RUNTIMEEOF
}

write_runtime_backend_config() {
  local backend_config_file="$1"
  local region
  local namespace
  local bucket_name

  region="$(resolve_output_or_env REGION "${FOUNDATION_DIR}" region)"
  namespace="$(resolve_output_or_env OCI_NAMESPACE "${FOUNDATION_DIR}" ocir_namespace)"
  bucket_name="$(resolve_output_or_env RUNTIME_STATE_BUCKET_NAME "${FOUNDATION_DIR}" terraform_state_bucket_name)"

  cat > "${backend_config_file}" <<EOF
region = "${region}"
namespace = "${namespace}"
bucket = "${bucket_name}"
key = "${RUNTIME_STATE_KEY}"
EOF

  if [[ "${OCI_CLI_AUTH:-}" == "resource_principal" ]]; then
    printf 'auth = "ResourcePrincipal"\n' >> "${backend_config_file}"
  fi
}

init_runtime_backend() {
  local backend_config_file
  backend_config_file="$(mktemp)"
  trap 'rm -f "${backend_config_file}"' RETURN

  require_command terraform
  write_runtime_backend_config "${backend_config_file}"

  if [[ -f "${RUNTIME_DIR}/terraform.tfstate" && "${RUNTIME_BACKEND_MIGRATE:-false}" != "true" ]]; then
    echo "Runtime local state detected at ${RUNTIME_DIR}/terraform.tfstate." >&2
    echo "Re-run with RUNTIME_BACKEND_MIGRATE=true to migrate it into the OCI backend before OCI DevOps rollout is enabled." >&2
    exit 1
  fi

  if [[ "${RUNTIME_BACKEND_MIGRATE:-false}" == "true" ]]; then
    terraform -chdir="${RUNTIME_DIR}" init -upgrade -reconfigure -migrate-state -force-copy -backend-config="${backend_config_file}"
    return
  fi

  terraform -chdir="${RUNTIME_DIR}" init -upgrade -reconfigure -backend-config="${backend_config_file}"
}

assert_runtime_execution_context() {
  if [[ "${RUNTIME_BACKEND_MIGRATE:-false}" == "true" ]]; then
    return 0
  fi

  if [[ "${OCI_CLI_AUTH:-}" == "resource_principal" ]]; then
    return 0
  fi

  echo "Production runtime apply is restricted to OCI DevOps. Use ./infrastructure/oci/devops/run-release.sh for releases, or set RUNTIME_BACKEND_MIGRATE=true for the one-time backend migration." >&2
  exit 1
}

apply_runtime() {
  local release_vars_file="${RUNTIME_DIR}/release.auto.tfvars"
  local image_tag
  local image_registry_username
  local image_registry_password

  assert_runtime_execution_context
  init_runtime_backend
  write_runtime_stack_vars
  image_tag="$(resolve_runtime_image_tag)"

  image_registry_username="${IMAGE_REGISTRY_USERNAME:-}"
  image_registry_password="${IMAGE_REGISTRY_PASSWORD:-}"

  if [[ -z "${image_registry_username}" && -n "${OCI_USERNAME:-}" && -n "${OCI_AUTH_TOKEN:-}" ]]; then
    local ocir_namespace
    ocir_namespace="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_namespace)"
    image_registry_username="${ocir_namespace}/${OCI_USERNAME}"
    image_registry_password="${OCI_AUTH_TOKEN}"
  fi

  if [[ -n "${image_registry_username}" && -n "${image_registry_password}" ]]; then
    cat > "${release_vars_file}" <<EOFVARS
image_tag               = "${image_tag}"
image_registry_username = "${image_registry_username}"
image_registry_password = "${image_registry_password}"
EOFVARS
  elif [[ ! -f "${release_vars_file}" ]]; then
    echo "Missing runtime registry credentials. Set IMAGE_REGISTRY_USERNAME and IMAGE_REGISTRY_PASSWORD, or provide runtime/release.auto.tfvars." >&2
    exit 1
  else
    upsert_tfvars_string "${release_vars_file}" "image_tag" "${image_tag}"
  fi

  terraform -chdir="${RUNTIME_DIR}" fmt
  terraform -chdir="${RUNTIME_DIR}" apply -auto-approve -input=false
}

case "${MODE}" in
  foundation)
    apply_foundation
    ;;
  devops)
    apply_devops
    ;;
  data)
    apply_data
    ;;
  db-role)
    bootstrap_runtime_db_role
    ;;
  runtime)
    apply_runtime
    ;;
  all)
    apply_foundation
    apply_data
    apply_runtime
    ;;
esac
