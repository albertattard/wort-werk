#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

require_var() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    echo "Missing required environment variable: ${var_name}" >&2
    exit 1
  fi
}

resolve_build_pipeline_id() {
  if [[ -n "${BUILD_PIPELINE_ID:-}" ]]; then
    printf '%s' "${BUILD_PIPELINE_ID}"
    return 0
  fi

  terraform -chdir="${SCRIPT_DIR}" output -raw build_pipeline_id
}

BUILD_PIPELINE_ID="$(resolve_build_pipeline_id)"
REPOSITORY_URL="${REPOSITORY_URL:-$(terraform -chdir="${SCRIPT_DIR}" output -raw repository_url 2>/dev/null || true)}"
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/albertattard/wort-werk.git}"
repository_branch="${REPOSITORY_BRANCH:-$(terraform -chdir="${SCRIPT_DIR}" output -raw repository_branch 2>/dev/null || true)}"
repository_branch="${repository_branch:-main}"
commit_hash="${COMMIT_HASH:-$(git -C "${REPO_ROOT}" rev-parse HEAD)}"
RELEASE_VERSION="${RELEASE_VERSION:-$(git -C "${REPO_ROOT}" rev-parse --short=12 "${commit_hash}")}"
TF_BACKEND_MODE="${TF_BACKEND_MODE:-local-blocked}"

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
    }
  ]
}
EOF

oci devops build-run create \
  --build-pipeline-id "${BUILD_PIPELINE_ID}" \
  --display-name "wort-werk-${RELEASE_VERSION}" \
  --commit-info "file://${commit_info_file}" \
  --build-run-arguments "file://${build_arguments_file}"
