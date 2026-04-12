#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUNDATION_DIR="${SCRIPT_DIR}/../foundation"
PROFILE="${OCI_PROFILE:-FRANKFURT}"
ADMIN_SECRET_NAME="${POSTGRESQL_ADMIN_SECRET_NAME:-wort-werk-db-admin-password}"
RUNTIME_SECRET_NAME="${RUNTIME_DB_SECRET_NAME:-wort-werk-db-runtime-password}"
TFVARS_FILE="${SCRIPT_DIR}/terraform.tfvars"
DEFAULT_POSTGRESQL_ADMIN_USERNAME="wortwerk_admin"
DEFAULT_RUNTIME_DB_USERNAME="wortwerk_app"
NON_INTERACTIVE="${WORTWERK_NONINTERACTIVE:-${CI:-}}"

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
}

require_non_empty() {
  local name="$1"
  local value="$2"
  if [[ -z "${value}" ]]; then
    echo "Missing required value: ${name}" >&2
    exit 1
  fi
}

prompt_secret() {
  local prompt="$1"
  local env_name="$2"
  local value

  if [[ -n "${NON_INTERACTIVE}" ]]; then
    echo "Missing required value: ${env_name}. Refusing interactive prompt in non-interactive mode." >&2
    exit 1
  fi

  if ! exec 3<> /dev/tty; then
    echo "Interactive secret prompt requires /dev/tty. Set ${env_name} explicitly or run interactively." >&2
    exit 1
  fi

  printf "%s:" "${prompt}" >&3
  IFS= read -rs value <&3
  printf "\n" >&3
  exec 3>&-
  exec 3<&-
  require_non_empty "${prompt}" "${value}"
  printf "%s" "${value}"
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

lookup_secret_id() {
  local secret_name="$1"

  oci vault secret list \
    --profile "${PROFILE}" \
    --compartment-id "${COMPARTMENT_OCID}" \
    --vault-id "${VAULT_OCID}" \
    --name "${secret_name}" \
    --all \
    --query 'data[0].id' \
    --raw-output
}

create_secret() {
  local secret_name="$1"
  local secret_value="$2"

  oci vault secret create-base64 \
    --profile "${PROFILE}" \
    --compartment-id "${COMPARTMENT_OCID}" \
    --vault-id "${VAULT_OCID}" \
    --key-id "${VAULT_KEY_OCID}" \
    --secret-name "${secret_name}" \
    --secret-content-content "$(printf '%s' "${secret_value}" | base64)" \
    --query 'data.id' \
    --raw-output
}

update_secret() {
  local secret_id="$1"
  local secret_value="$2"

  oci vault secret update-base64 \
    --profile "${PROFILE}" \
    --secret-id "${secret_id}" \
    --secret-content-content "$(printf '%s' "${secret_value}" | base64)" \
    --force >/dev/null
}

upsert_secret() {
  local secret_name="$1"
  local secret_value="$2"
  local existing_id

  existing_id="$(lookup_secret_id "${secret_name}")"
  if [[ -n "${existing_id}" && "${existing_id}" != "null" ]]; then
    update_secret "${existing_id}" "${secret_value}"
    printf "%s" "${existing_id}"
    return 0
  fi

  create_secret "${secret_name}" "${secret_value}"
}

require_command terraform
require_command oci

COMPARTMENT_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
VAULT_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw vault_id)"
VAULT_KEY_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw vault_key_id)"

require_non_empty "COMPARTMENT_OCID" "${COMPARTMENT_OCID}"
require_non_empty "VAULT_OCID" "${VAULT_OCID}"
require_non_empty "VAULT_KEY_OCID" "${VAULT_KEY_OCID}"

POSTGRESQL_ADMIN_PASSWORD="${POSTGRESQL_ADMIN_PASSWORD:-}"
RUNTIME_DB_PASSWORD="${RUNTIME_DB_PASSWORD:-}"
RUNTIME_DB_USERNAME="${RUNTIME_DB_USERNAME:-$(read_tfvars_string "${TFVARS_FILE}" "runtime_db_username")}"
RUNTIME_DB_USERNAME="${RUNTIME_DB_USERNAME:-${DEFAULT_RUNTIME_DB_USERNAME}}"

if [[ -z "${POSTGRESQL_ADMIN_PASSWORD}" ]]; then
  POSTGRESQL_ADMIN_PASSWORD="$(prompt_secret "PostgreSQL admin password: " "POSTGRESQL_ADMIN_PASSWORD")"
fi

if [[ "${RUNTIME_DB_USERNAME}" == "${DEFAULT_POSTGRESQL_ADMIN_USERNAME}" ]]; then
  echo "runtime_db_username must be a dedicated non-admin application role, not ${DEFAULT_POSTGRESQL_ADMIN_USERNAME}." >&2
  exit 1
fi

if [[ -z "${RUNTIME_DB_PASSWORD}" ]]; then
  RUNTIME_DB_PASSWORD="$(prompt_secret "Runtime DB password: " "RUNTIME_DB_PASSWORD")"
fi

trap 'unset POSTGRESQL_ADMIN_PASSWORD RUNTIME_DB_PASSWORD' EXIT

POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID="$(
  upsert_secret "${ADMIN_SECRET_NAME}" "${POSTGRESQL_ADMIN_PASSWORD}"
)"
RUNTIME_DB_PASSWORD_SECRET_OCID="$(
  upsert_secret "${RUNTIME_SECRET_NAME}" "${RUNTIME_DB_PASSWORD}"
)"

umask 077
cat > "${TFVARS_FILE}" <<EOF
postgresql_admin_password_secret_ocid = "${POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID}"
runtime_db_password_secret_ocid       = "${RUNTIME_DB_PASSWORD_SECRET_OCID}"
EOF

cat <<EOF
Updated Vault secrets and wrote:
  ${TFVARS_FILE}

postgresql_admin_password_secret_ocid = ${POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID}
runtime_db_password_secret_ocid       = ${RUNTIME_DB_PASSWORD_SECRET_OCID}

Next:
  terraform -chdir=${SCRIPT_DIR} init
  terraform -chdir=${SCRIPT_DIR} plan
  terraform -chdir=${SCRIPT_DIR} apply
EOF
