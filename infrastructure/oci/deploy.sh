#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
FOUNDATION_DIR="${SCRIPT_DIR}/foundation"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
MODE="${1:-all}"

if [[ "${MODE}" != "all" && "${MODE}" != "foundation" && "${MODE}" != "runtime" && "${MODE}" != "release" ]]; then
  echo "Usage: $0 [all|foundation|runtime|release]" >&2
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

apply_foundation() {
  terraform -chdir="${FOUNDATION_DIR}" init -upgrade
  terraform -chdir="${FOUNDATION_DIR}" fmt
  terraform -chdir="${FOUNDATION_DIR}" apply -auto-approve -input=false
}

write_runtime_foundation_vars() {
  local compartment_ocid
  local subnet_id
  local nsg_id

  compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
  subnet_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw subnet_id)"
  nsg_id="$(terraform -chdir="${FOUNDATION_DIR}" output -raw nsg_id)"

  cat > "${RUNTIME_DIR}/foundation.auto.tfvars" <<EOF
compartment_ocid = "${compartment_ocid}"
subnet_id        = "${subnet_id}"
nsg_id           = "${nsg_id}"
EOF
}

apply_runtime() {
  write_runtime_foundation_vars
  terraform -chdir="${RUNTIME_DIR}" init -upgrade
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
  local oci_region
  local oci_repository
  local image_tag
  local image_repository
  local image
  local compartment_ocid
  local keep_count

  require_command terraform
  require_command docker
  require_command git
  require_command oci
  require_var OCI_PROFILE
  require_var OCI_USERNAME
  require_var OCI_AUTH_TOKEN

  oci_region="${OCI_REGION:-fra}"
  image_tag="${IMAGE_TAG:-$(git -C "${REPO_ROOT}" rev-parse --short=12 HEAD)}"
  keep_count="${KEEP_IMAGE_COUNT:-2}"

  compartment_ocid="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
  oci_repository="${OCIR_REPOSITORY:-$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_repository_name)}"
  OCIR_NAMESPACE="${OCIR_NAMESPACE:-$(oci os ns get --profile "${OCI_PROFILE}" --query 'data' --raw-output)}"

  image_repository="${oci_region}.ocir.io/${OCIR_NAMESPACE}/${oci_repository}"
  image="${image_repository}:${image_tag}"

  echo "Logging into OCIR: ${oci_region}.ocir.io"
  printf '%s' "${OCI_AUTH_TOKEN}" | docker login "${oci_region}.ocir.io" \
    --username "${OCIR_NAMESPACE}/${OCI_USERNAME}" \
    --password-stdin

  echo "Building and pushing image: ${image}"
  docker buildx build \
    --file "${REPO_ROOT}/container/Dockerfile" \
    --platform "${DOCKER_PLATFORM:-linux/amd64,linux/arm64}" \
    --tag "${image}" \
    --push \
    "${REPO_ROOT}"

  write_runtime_foundation_vars
  cat > "${RUNTIME_DIR}/release.auto.tfvars" <<EOF
image_repository = "${image_repository}"
image_tag        = "${image_tag}"
EOF

  terraform -chdir="${RUNTIME_DIR}" init -upgrade
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
  runtime)
    apply_runtime
    ;;
  release)
    deploy_release
    ;;
  all)
    apply_foundation
    apply_runtime
    ;;
esac
