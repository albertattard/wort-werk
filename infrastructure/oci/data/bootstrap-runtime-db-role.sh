#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}"
PROFILE="${OCI_PROFILE:-FRANKFURT}"
TFVARS_FILE="${DATA_DIR}/terraform.tfvars"
DEFAULT_POSTGRESQL_ADMIN_USERNAME="wortwerk_admin"
DEFAULT_RUNTIME_DB_USERNAME="wortwerk_app"

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

validate_role_name() {
  local role_name="$1"
  if [[ ! "${role_name}" =~ ^[a-z_][a-z0-9_]{0,62}$ ]]; then
    echo "runtime_db_username must be a simple PostgreSQL identifier matching ^[a-z_][a-z0-9_]{0,62}$." >&2
    exit 1
  fi
}

base64_decode() {
  if base64 --help 2>&1 | grep -q -- '--decode'; then
    base64 --decode
    return 0
  fi

  base64 -D
}

read_secret_value() {
  local secret_id="$1"
  local oci_args=()

  if [[ "${OCI_CLI_AUTH:-}" == "resource_principal" ]]; then
    oci_args+=(--auth resource_principal)
  else
    oci_args+=(--profile "${PROFILE}")
  fi

  oci secrets secret-bundle get \
    "${oci_args[@]}" \
    --secret-id "${secret_id}" \
    --query 'data."secret-bundle-content".content' \
    --raw-output | base64_decode
}

require_command terraform
require_command oci
require_command psql
require_command base64

POSTGRESQL_ADMIN_USERNAME="${POSTGRESQL_ADMIN_USERNAME:-$(read_tfvars_string "${TFVARS_FILE}" "postgresql_admin_username")}"
POSTGRESQL_ADMIN_USERNAME="${POSTGRESQL_ADMIN_USERNAME:-${DEFAULT_POSTGRESQL_ADMIN_USERNAME}}"
RUNTIME_DB_USERNAME="${RUNTIME_DB_USERNAME:-$(read_tfvars_string "${TFVARS_FILE}" "runtime_db_username")}"
RUNTIME_DB_USERNAME="${RUNTIME_DB_USERNAME:-${DEFAULT_RUNTIME_DB_USERNAME}}"
POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID="${POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID:-$(read_tfvars_string "${TFVARS_FILE}" "postgresql_admin_password_secret_ocid")}"
RUNTIME_DB_PASSWORD_SECRET_OCID="${RUNTIME_DB_PASSWORD_SECRET_OCID:-$(read_tfvars_string "${TFVARS_FILE}" "runtime_db_password_secret_ocid")}"
POSTGRESQL_HOST="${POSTGRESQL_HOST:-$(terraform -chdir="${DATA_DIR}" output -raw postgresql_fqdn)}"
POSTGRESQL_PORT="${POSTGRESQL_PORT:-$(terraform -chdir="${DATA_DIR}" output -raw postgresql_port)}"
POSTGRESQL_DATABASE_NAME="${POSTGRESQL_DATABASE_NAME:-$(terraform -chdir="${DATA_DIR}" output -raw postgresql_database_name)}"
POSTGRESQL_SSL_ROOT_CERT_BASE64="${POSTGRESQL_SSL_ROOT_CERT_BASE64:-${RUNTIME_DB_SSL_ROOT_CERT_BASE64:-$(terraform -chdir="${DATA_DIR}" output -raw runtime_db_ssl_root_cert_base64)}}"

require_non_empty "POSTGRESQL_ADMIN_USERNAME" "${POSTGRESQL_ADMIN_USERNAME}"
require_non_empty "RUNTIME_DB_USERNAME" "${RUNTIME_DB_USERNAME}"
require_non_empty "POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID" "${POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID}"
require_non_empty "RUNTIME_DB_PASSWORD_SECRET_OCID" "${RUNTIME_DB_PASSWORD_SECRET_OCID}"
require_non_empty "POSTGRESQL_HOST" "${POSTGRESQL_HOST}"
require_non_empty "POSTGRESQL_PORT" "${POSTGRESQL_PORT}"
require_non_empty "POSTGRESQL_DATABASE_NAME" "${POSTGRESQL_DATABASE_NAME}"
require_non_empty "POSTGRESQL_SSL_ROOT_CERT_BASE64" "${POSTGRESQL_SSL_ROOT_CERT_BASE64}"
validate_role_name "${RUNTIME_DB_USERNAME}"

if [[ "${RUNTIME_DB_USERNAME}" == "${POSTGRESQL_ADMIN_USERNAME}" ]]; then
  echo "runtime_db_username must be a dedicated non-admin application role, not ${POSTGRESQL_ADMIN_USERNAME}." >&2
  exit 1
fi

POSTGRESQL_ADMIN_PASSWORD="$(read_secret_value "${POSTGRESQL_ADMIN_PASSWORD_SECRET_OCID}")"
RUNTIME_DB_PASSWORD="$(read_secret_value "${RUNTIME_DB_PASSWORD_SECRET_OCID}")"

require_non_empty "POSTGRESQL_ADMIN_PASSWORD" "${POSTGRESQL_ADMIN_PASSWORD}"
require_non_empty "RUNTIME_DB_PASSWORD" "${RUNTIME_DB_PASSWORD}"

SSL_ROOT_CERT_FILE="$(mktemp)"
trap 'rm -f "${SSL_ROOT_CERT_FILE}"; unset POSTGRESQL_ADMIN_PASSWORD RUNTIME_DB_PASSWORD RUNTIME_DB_BOOTSTRAP_PASSWORD' EXIT
printf '%s' "${POSTGRESQL_SSL_ROOT_CERT_BASE64}" | base64_decode > "${SSL_ROOT_CERT_FILE}"
if [[ ! -s "${SSL_ROOT_CERT_FILE}" ]]; then
  echo "Failed to decode PostgreSQL SSL root certificate." >&2
  exit 1
fi
chmod 600 "${SSL_ROOT_CERT_FILE}"

export PGPASSWORD="${POSTGRESQL_ADMIN_PASSWORD}"
export PGSSLMODE="verify-full"
export PGSSLROOTCERT="${SSL_ROOT_CERT_FILE}"
export RUNTIME_DB_BOOTSTRAP_PASSWORD="${RUNTIME_DB_PASSWORD}"

psql \
  --host="${POSTGRESQL_HOST}" \
  --port="${POSTGRESQL_PORT}" \
  --username="${POSTGRESQL_ADMIN_USERNAME}" \
  --dbname="${POSTGRESQL_DATABASE_NAME}" \
  --set=ON_ERROR_STOP=1 \
  --set=postgresql_database_name="${POSTGRESQL_DATABASE_NAME}" \
  --set=runtime_db_username="${RUNTIME_DB_USERNAME}" <<'SQL'
\getenv runtime_db_password RUNTIME_DB_BOOTSTRAP_PASSWORD

DO $bootstrap$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'runtime_db_username') THEN
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', :'runtime_db_username', :'runtime_db_password');
  ELSE
    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', :'runtime_db_username', :'runtime_db_password');
  END IF;
END
$bootstrap$;

SELECT format('GRANT CONNECT, TEMPORARY ON DATABASE %I TO %I', :'postgresql_database_name', :'runtime_db_username')
\gexec

SELECT format('GRANT USAGE, CREATE ON SCHEMA public TO %I', :'runtime_db_username')
\gexec

SELECT format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO %I', :'runtime_db_username')
\gexec

SELECT format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO %I', :'runtime_db_username')
\gexec

SELECT format('GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO %I', :'runtime_db_username')
\gexec

SELECT format('ALTER TABLE %I.%I OWNER TO %I', schemaname, tablename, :'runtime_db_username')
FROM pg_tables
WHERE schemaname = 'public'
\gexec

SELECT format('ALTER SEQUENCE %I.%I OWNER TO %I', sequence_schema, sequence_name, :'runtime_db_username')
FROM information_schema.sequences
WHERE sequence_schema = 'public'
\gexec

SELECT format('ALTER VIEW %I.%I OWNER TO %I', schemaname, viewname, :'runtime_db_username')
FROM pg_views
WHERE schemaname = 'public'
\gexec

SELECT format('ALTER MATERIALIZED VIEW %I.%I OWNER TO %I', schemaname, matviewname, :'runtime_db_username')
FROM pg_matviews
WHERE schemaname = 'public'
\gexec
SQL

cat <<EOF
Bootstrapped runtime DB role:
  runtime_db_username = ${RUNTIME_DB_USERNAME}
  host                = ${POSTGRESQL_HOST}
  database            = ${POSTGRESQL_DATABASE_NAME}

This step must be re-run after rotating the runtime DB password secret or after administrator-created schema objects need to be handed back to the runtime role.
EOF
