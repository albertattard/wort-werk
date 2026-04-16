#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOUNDATION_DIR="${SCRIPT_DIR}/../foundation"
PROFILE="${OCI_PROFILE:-FRANKFURT}"
PUBLIC_SECRET_NAME="${TLS_PUBLIC_CERTIFICATE_SECRET_NAME:-wort-werk-tls-public-certificate}"
PRIVATE_SECRET_NAME="${TLS_PRIVATE_KEY_SECRET_NAME:-wort-werk-tls-private-key}"
CA_SECRET_NAME="${TLS_CA_CERTIFICATE_SECRET_NAME:-wort-werk-tls-ca-certificate}"
TFVARS_FILE="${SCRIPT_DIR}/terraform.tfvars"

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
    printf '%s' "${existing_id}"
    return 0
  fi

  create_secret "${secret_name}" "${secret_value}"
}

read_pem() {
  local label="$1"
  local file_path="$2"

  require_non_empty "${label}" "${file_path}"
  if [[ ! -f "${file_path}" ]]; then
    echo "File not found for ${label}: ${file_path}" >&2
    exit 1
  fi

  cat "${file_path}"
}

require_command terraform
require_command oci

COMPARTMENT_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
VAULT_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw vault_id)"
VAULT_KEY_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw vault_key_id)"

require_non_empty "COMPARTMENT_OCID" "${COMPARTMENT_OCID}"
require_non_empty "VAULT_OCID" "${VAULT_OCID}"
require_non_empty "VAULT_KEY_OCID" "${VAULT_KEY_OCID}"

TLS_PUBLIC_CERTIFICATE_FILE="${TLS_PUBLIC_CERTIFICATE_FILE:-}"
TLS_PRIVATE_KEY_FILE="${TLS_PRIVATE_KEY_FILE:-}"
TLS_CA_CERTIFICATE_FILE="${TLS_CA_CERTIFICATE_FILE:-}"
TLS_PUBLIC_CERTIFICATE_PEM="${TLS_PUBLIC_CERTIFICATE_PEM:-}"
TLS_PRIVATE_KEY_PEM="${TLS_PRIVATE_KEY_PEM:-}"
TLS_CA_CERTIFICATE_PEM="${TLS_CA_CERTIFICATE_PEM:-}"

if [[ -z "${TLS_PUBLIC_CERTIFICATE_PEM}" ]]; then
  TLS_PUBLIC_CERTIFICATE_PEM="$(read_pem "TLS_PUBLIC_CERTIFICATE_FILE" "${TLS_PUBLIC_CERTIFICATE_FILE}")"
fi

if [[ -z "${TLS_PRIVATE_KEY_PEM}" ]]; then
  TLS_PRIVATE_KEY_PEM="$(read_pem "TLS_PRIVATE_KEY_FILE" "${TLS_PRIVATE_KEY_FILE}")"
fi

if [[ -z "${TLS_CA_CERTIFICATE_PEM}" && -n "${TLS_CA_CERTIFICATE_FILE}" ]]; then
  TLS_CA_CERTIFICATE_PEM="$(read_pem "TLS_CA_CERTIFICATE_FILE" "${TLS_CA_CERTIFICATE_FILE}")"
fi

trap 'unset TLS_PUBLIC_CERTIFICATE_PEM TLS_PRIVATE_KEY_PEM TLS_CA_CERTIFICATE_PEM' EXIT

TLS_PUBLIC_CERTIFICATE_SECRET_OCID="$(
  upsert_secret "${PUBLIC_SECRET_NAME}" "${TLS_PUBLIC_CERTIFICATE_PEM}"
)"
TLS_PRIVATE_KEY_SECRET_OCID="$(
  upsert_secret "${PRIVATE_SECRET_NAME}" "${TLS_PRIVATE_KEY_PEM}"
)"

upsert_tfvars_string "${TFVARS_FILE}" "tls_public_certificate_secret_ocid" "${TLS_PUBLIC_CERTIFICATE_SECRET_OCID}"
upsert_tfvars_string "${TFVARS_FILE}" "tls_private_key_secret_ocid" "${TLS_PRIVATE_KEY_SECRET_OCID}"

if [[ -n "${TLS_CA_CERTIFICATE_PEM}" ]]; then
  TLS_CA_CERTIFICATE_SECRET_OCID="$(
    upsert_secret "${CA_SECRET_NAME}" "${TLS_CA_CERTIFICATE_PEM}"
  )"
  upsert_tfvars_string "${TFVARS_FILE}" "tls_ca_certificate_secret_ocid" "${TLS_CA_CERTIFICATE_SECRET_OCID}"
fi

cat <<EOF
Updated Vault secrets and wrote:
  ${TFVARS_FILE}

tls_public_certificate_secret_ocid = ${TLS_PUBLIC_CERTIFICATE_SECRET_OCID}
tls_private_key_secret_ocid        = ${TLS_PRIVATE_KEY_SECRET_OCID}
EOF

if [[ -n "${TLS_CA_CERTIFICATE_PEM}" ]]; then
  cat <<EOF
tls_ca_certificate_secret_ocid     = ${TLS_CA_CERTIFICATE_SECRET_OCID}
EOF
else
  cat <<EOF
tls_ca_certificate_secret_ocid     = $(read_tfvars_string "${TFVARS_FILE}" "tls_ca_certificate_secret_ocid")
EOF
fi

cat <<EOF

Next:
  ./infrastructure/oci/deploy.sh devops
  OCI_CLI_REGION=eu-frankfurt-1 ./infrastructure/oci/devops/run-release.sh
EOF
