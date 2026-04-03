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
