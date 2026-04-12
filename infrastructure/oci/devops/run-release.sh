#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
FOUNDATION_DIR="${REPO_ROOT}/infrastructure/oci/foundation"
DATA_DIR="${REPO_ROOT}/infrastructure/oci/data"
DEVOPS_TFVARS_FILE="${SCRIPT_DIR}/terraform.tfvars"

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

resolve_build_pipeline_id() {
  if [[ -n "${BUILD_PIPELINE_ID:-}" ]]; then
    printf '%s' "${BUILD_PIPELINE_ID}"
    return 0
  fi

  terraform -chdir="${SCRIPT_DIR}" output -raw build_pipeline_id
}

resolve_devops_string() {
  local env_name="$1"
  local tfvars_key="$2"
  local value="${!env_name:-$(read_tfvars_string "${DEVOPS_TFVARS_FILE}" "${tfvars_key}")}"

  if [[ -z "${value}" ]]; then
    echo "Missing required DevOps value: ${env_name} / ${tfvars_key}" >&2
    exit 1
  fi

  printf '%s' "${value}"
}

BUILD_PIPELINE_ID="$(resolve_build_pipeline_id)"
REPOSITORY_URL="${REPOSITORY_URL:-$(terraform -chdir="${SCRIPT_DIR}" output -raw repository_url 2>/dev/null || true)}"
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/albertattard/wort-werk.git}"
repository_branch="${REPOSITORY_BRANCH:-$(terraform -chdir="${SCRIPT_DIR}" output -raw repository_branch 2>/dev/null || true)}"
repository_branch="${repository_branch:-main}"
commit_hash="${COMMIT_HASH:-$(git -C "${REPO_ROOT}" rev-parse HEAD)}"
RELEASE_VERSION="${RELEASE_VERSION:-$(git -C "${REPO_ROOT}" rev-parse --short=12 "${commit_hash}")}"
TF_BACKEND_MODE="${TF_BACKEND_MODE:-remote}"
IMAGE_REGISTRY_USERNAME="$(resolve_devops_string IMAGE_REGISTRY_USERNAME image_registry_username)"
IMAGE_REGISTRY_PASSWORD_SECRET_OCID="$(resolve_devops_string IMAGE_REGISTRY_PASSWORD_SECRET_OCID image_registry_password_secret_ocid)"

require_var BUILD_PIPELINE_ID
require_var REPOSITORY_URL
require_var repository_branch
require_var commit_hash
require_var RELEASE_VERSION

commit_info_file="$(mktemp)"
build_arguments_file="$(mktemp)"
trap 'rm -f "${commit_info_file}" "${build_arguments_file}"' EXIT

cat > "${commit_info_file}" <<EOF
{
  "commitHash": "${commit_hash}",
  "repositoryBranch": "${repository_branch}",
  "repositoryUrl": "${REPOSITORY_URL}"
}
EOF

cat > "${build_arguments_file}" <<EOF
{
  "items": [
    {
      "name": "releaseVersion",
      "value": "${RELEASE_VERSION}"
    },
    {
      "name": "tfBackendMode",
      "value": "${TF_BACKEND_MODE}"
    },
    {
      "name": "imageRepository",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw image_repository)"
    },
    {
      "name": "imageRegistryEndpoint",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_registry)"
    },
    {
      "name": "imageRegistryUsername",
      "value": "${IMAGE_REGISTRY_USERNAME}"
    },
    {
      "name": "imageRegistryPasswordSecretOcid",
      "value": "${IMAGE_REGISTRY_PASSWORD_SECRET_OCID}"
    },
    {
      "name": "regionRuntime",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw region)"
    },
    {
      "name": "tenancyOcid",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw tenancy_ocid)"
    },
    {
      "name": "compartmentOcid",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
    },
    {
      "name": "runtimeSubnetId",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw runtime_subnet_id)"
    },
    {
      "name": "loadBalancerSubnetId",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_subnet_id)"
    },
    {
      "name": "nsgId",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw nsg_id)"
    },
    {
      "name": "loadBalancerNsgId",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_nsg_id)"
    },
    {
      "name": "loadBalancerPublicIpId",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip_id)"
    },
    {
      "name": "loadBalancerPublicIp",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_public_ip)"
    },
    {
      "name": "appPort",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw app_port)"
    },
    {
      "name": "managementPort",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw management_port)"
    },
    {
      "name": "lbListenerPort",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw lb_listener_port)"
    },
    {
      "name": "httpsListenerPort",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw https_listener_port)"
    },
    {
      "name": "loadBalancerMinBandwidthMbps",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_min_bandwidth_mbps)"
    },
    {
      "name": "loadBalancerMaxBandwidthMbps",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw load_balancer_max_bandwidth_mbps)"
    },
    {
      "name": "runtimeDbUrl",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_url)"
    },
    {
      "name": "runtimeDbUsername",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_username)"
    },
    {
      "name": "runtimeDbPasswordSecretOcid",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_password_secret_ocid)"
    },
    {
      "name": "runtimeDbSslRootCertBase64",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_ssl_root_cert_base64)"
    },
    {
      "name": "postgresqlAdminUsername",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw postgresql_admin_username)"
    },
    {
      "name": "postgresqlAdminPasswordSecretOcid",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw postgresql_admin_password_secret_ocid)"
    },
    {
      "name": "postgresqlHost",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw postgresql_fqdn)"
    },
    {
      "name": "postgresqlPort",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw postgresql_port)"
    },
    {
      "name": "postgresqlDatabaseName",
      "value": "$(terraform -chdir="${DATA_DIR}" output -raw postgresql_database_name)"
    },
    {
      "name": "runtimeStateBucketName",
      "value": "$(terraform -chdir="${FOUNDATION_DIR}" output -raw terraform_state_bucket_name)"
    }
  ]
}
EOF

oci devops build-run create \
  --build-pipeline-id "${BUILD_PIPELINE_ID}" \
  --display-name "wort-werk-${RELEASE_VERSION}" \
  --commit-info "file://${commit_info_file}" \
  --build-run-arguments "file://${build_arguments_file}"
