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

if [[ "${MODE}" != "all" && "${MODE}" != "foundation" && "${MODE}" != "devops" && "${MODE}" != "data" && "${MODE}" != "db-role" && "${MODE}" != "runtime" && "${MODE}" != "release" && "${MODE}" != "rollout" ]]; then
  echo "Usage: $0 [all|foundation|devops|data|db-role|runtime|release|rollout]" >&2
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

  echo "Missing image_tag for runtime apply. Set IMAGE_TAG or run release first so runtime state has deployed_image_url." >&2
  exit 1
}

ensure_clean_rollout_worktree() {
  if [[ "${ALLOW_DIRTY_ROLLOUT:-false}" == "true" ]]; then
    echo "Skipping rollout clean-worktree preflight because ALLOW_DIRTY_ROLLOUT=true."
    return
  fi

  local pending
  pending="$(git -C "${REPO_ROOT}" status --short -- . ':(exclude)assets/images/new')"
  if [[ -n "${pending}" ]]; then
    echo "Rollout aborted: pending git changes detected outside assets/images/new." >&2
    echo "${pending}" >&2
    echo "Commit or stash these changes, or set ALLOW_DIRTY_ROLLOUT=true for an intentional one-off rollout." >&2
    exit 1
  fi
}

apply_foundation() {
  terraform -chdir="${FOUNDATION_DIR}" init -upgrade
  terraform -chdir="${FOUNDATION_DIR}" fmt
  terraform -chdir="${FOUNDATION_DIR}" apply -auto-approve -input=false
}

write_devops_stack_vars() {
  local region
  local home_region
  local compartment_ocid
  local devops_subnet_id
  local devops_nsg_id
  local devops_dynamic_group_name

  region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw region)"
  home_region="$(terraform -chdir="${FOUNDATION_DIR}" output -raw home_region)"
  compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
  devops_subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw devops_subnet_id)"
  devops_nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw devops_nsg_id)"
  devops_dynamic_group_name="$(terraform -chdir="${FOUNDATION_DIR}" output -raw devops_dynamic_group_name)"

  cat > "${DEVOPS_DIR}/foundation.auto.tfvars" <<DEVOPSEOF
region = "${region}"
home_region = "${home_region}"
compartment_ocid = "${compartment_ocid}"
devops_subnet_id = "${devops_subnet_id}"
devops_nsg_id = "${devops_nsg_id}"
devops_dynamic_group_name = "${devops_dynamic_group_name}"
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

apply_runtime() {
  local release_vars_file="${RUNTIME_DIR}/release.auto.tfvars"
  local image_tag

  terraform -chdir="${RUNTIME_DIR}" init -upgrade

  write_runtime_stack_vars
  image_tag="$(resolve_runtime_image_tag)"

  if [[ -n "${OCI_USERNAME:-}" && -n "${OCI_AUTH_TOKEN:-}" ]]; then
    local ocir_namespace
    ocir_namespace="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_namespace)"
    cat > "${release_vars_file}" <<EOFVARS
image_tag               = "${image_tag}"
image_registry_username = "${ocir_namespace}/${OCI_USERNAME}"
image_registry_password = "${OCI_AUTH_TOKEN}"
EOFVARS
  elif [[ ! -f "${release_vars_file}" ]]; then
    echo "Missing runtime registry credentials. Set OCI_USERNAME and OCI_AUTH_TOKEN or provide runtime/release.auto.tfvars." >&2
    exit 1
  else
    upsert_tfvars_string "${release_vars_file}" "image_tag" "${image_tag}"
  fi

  terraform -chdir="${RUNTIME_DIR}" fmt
  terraform -chdir="${RUNTIME_DIR}" apply -auto-approve -input=false
}

delete_old_images() {
  local compartment_ocid="$1"
  local repository_name="$2"
  local keep_count="$3"
  local repository_id
  local image_ids
  local total
  local i

  if (( keep_count < 2 )); then
    echo "KEEP_IMAGE_COUNT must be at least 2 for safe rollback; using 2." >&2
    keep_count=2
  fi

  repository_id="$(oci artifacts container repository list \
    --profile "${OCI_PROFILE}" \
    --compartment-id "${compartment_ocid}" \
    --display-name "${repository_name}" \
    --all \
    --query 'data[0].id' \
    --raw-output)"

  if [[ -z "${repository_id}" || "${repository_id}" == "null" ]]; then
    echo "Unable to resolve OCIR repository id for ${repository_name}." >&2
    exit 1
  fi

  mapfile -t image_ids < <(oci artifacts container image list \
    --profile "${OCI_PROFILE}" \
    --compartment-id "${compartment_ocid}" \
    --repository-id "${repository_id}" \
    --all \
    --query 'reverse(sort_by(data, &"time-created"))[].id' \
    --raw-output)

  total="${#image_ids[@]}"
  if (( total <= keep_count )); then
    echo "Image cleanup skipped: ${total} image(s) found, keep count is ${keep_count}."
    return
  fi

  echo "Pruning old images: keeping ${keep_count}, deleting $((total - keep_count))."
  for (( i=keep_count; i<total; i++ )); do
    oci artifacts container image delete \
      --profile "${OCI_PROFILE}" \
      --image-id "${image_ids[$i]}" \
      --force
  done
}

deploy_release() {
  local oci_repository
  local ocir_namespace
  local image_repository
  local registry_host
  local image_tag
  local image
  local verify_image
  local verify_image_repository
  local release_platforms
  local compartment_ocid
  local keep_count

  require_command terraform
  require_command docker
  require_command git
  require_command oci
  require_command "${REPO_ROOT}/mvnw"
  require_var OCI_USERNAME
  require_var OCI_AUTH_TOKEN

  OCI_PROFILE="${OCI_PROFILE:-FRANKFURT}"
  image_tag="${IMAGE_TAG:-$(git -C "${REPO_ROOT}" rev-parse --short=12 HEAD)}"
  keep_count="${KEEP_IMAGE_COUNT:-2}"
  verify_image_repository="$(basename "${REPO_ROOT}")"
  verify_image="${VERIFY_IMAGE_TAG:-${verify_image_repository}:verify-release}"
  release_platforms="${DOCKER_PLATFORM:-linux/amd64,linux/arm64}"

  compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
  oci_repository="${OCIR_REPOSITORY:-$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_repository_name)}"
  ocir_namespace="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_namespace)"
  image_repository="$(terraform -chdir="${FOUNDATION_DIR}" output -raw image_repository)"
  registry_host="${image_repository%%/*}"

  image="${image_repository}:${image_tag}"

  echo "Running pre-release verification: ./mvnw clean verify -Dverify.container.image=${verify_image}"
  "${REPO_ROOT}/mvnw" clean verify "-Dverify.container.image=${verify_image}"

  echo "Logging into OCIR: ${registry_host}"
  printf '%s' "${OCI_AUTH_TOKEN}" | docker login "${registry_host}" \
    --username "${ocir_namespace}/${OCI_USERNAME}" \
    --password-stdin

  docker image inspect "${verify_image}" >/dev/null 2>&1 || {
    echo "Verified image not found locally: ${verify_image}" >&2
    exit 1
  }

  echo "Publishing multi-architecture release image '${image}' for platforms '${release_platforms}'"
  docker buildx build \
    --file "${REPO_ROOT}/container/Dockerfile" \
    --platform "${release_platforms}" \
    --tag "${image}" \
    --push \
    "${REPO_ROOT}"

  write_runtime_stack_vars
  cat > "${RUNTIME_DIR}/release.auto.tfvars" <<EOFVARS
image_tag               = "${image_tag}"
image_registry_username = "${ocir_namespace}/${OCI_USERNAME}"
image_registry_password = "${OCI_AUTH_TOKEN}"
EOFVARS

  terraform -chdir="${RUNTIME_DIR}" init -upgrade
  terraform -chdir="${RUNTIME_DIR}" fmt
  terraform -chdir="${RUNTIME_DIR}" apply -auto-approve -input=false

  if [[ "${PRUNE_OLD_IMAGES:-true}" == "true" ]]; then
    delete_old_images "${compartment_ocid}" "${oci_repository}" "${keep_count}"
  else
    echo "Skipping image cleanup because PRUNE_OLD_IMAGES=false."
  fi
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
  release)
    deploy_release
    ;;
  rollout)
    ensure_clean_rollout_worktree
    apply_foundation
    apply_data
    deploy_release
    ;;
  all)
    apply_foundation
    apply_data
    apply_runtime
    ;;
esac
