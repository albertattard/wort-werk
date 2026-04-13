#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

COMMAND="${1:-}"
TARGET_DIR="${2:-}"

VERIFY_ENV_BACKEND="${VERIFY_ENV_BACKEND:-compose}"
VERIFY_COMPOSE_FILE="${VERIFY_COMPOSE_FILE:-${REPO_ROOT}/container/compose.verify.yml}"
VERIFY_COMPOSE_PROJECT="${VERIFY_COMPOSE_PROJECT:-wort-werk-verify}"
VERIFY_APP_CONTAINER_NAME="${VERIFY_APP_CONTAINER_NAME:-${VERIFY_COMPOSE_PROJECT}-app}"
VERIFY_DB_CONTAINER_NAME="${VERIFY_DB_CONTAINER_NAME:-${VERIFY_COMPOSE_PROJECT}-db}"
VERIFY_NETWORK_NAME="${VERIFY_NETWORK_NAME:-${VERIFY_COMPOSE_PROJECT}}"

usage() {
  echo "Usage: $0 <up|wait|logs|down|capture-logs|capture-and-down> [target-dir]" >&2
  exit 1
}

require_common_env() {
  local required=(
    VERIFY_CONTAINER_IMAGE
    VERIFY_CONTAINER_PORT
    VERIFY_DB_PORT
    VERIFY_DB_NAME
    VERIFY_DB_USERNAME
    VERIFY_DB_PASSWORD
  )

  local name
  for name in "${required[@]}"; do
    if [[ -z "${!name:-}" ]]; then
      echo "Missing required environment variable: ${name}" >&2
      exit 1
    fi
  done
}

compose_cmd() {
  docker compose --file "${VERIFY_COMPOSE_FILE}" --project-name "${VERIFY_COMPOSE_PROJECT}" "$@"
}

podman_db_health() {
  podman inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
    "${VERIFY_DB_CONTAINER_NAME}" 2>/dev/null || true
}

podman_db_is_running() {
  [[ "$(podman_db_health)" == "running" ]]
}

podman_db_is_ready() {
  podman exec "${VERIFY_DB_CONTAINER_NAME}" \
    pg_isready \
    --username="${VERIFY_DB_USERNAME}" \
    --dbname="${VERIFY_DB_NAME}" >/dev/null 2>&1
}

print_logs() {
  case "${VERIFY_ENV_BACKEND}" in
    compose)
      compose_cmd logs --no-color app db || true
      ;;
    podman)
      podman logs "${VERIFY_APP_CONTAINER_NAME}" || true
      podman logs "${VERIFY_DB_CONTAINER_NAME}" || true
      ;;
    *)
      echo "Unsupported verification backend: ${VERIFY_ENV_BACKEND}" >&2
      exit 1
      ;;
  esac
}

capture_logs() {
  local target_dir="$1"
  mkdir -p "${target_dir}"

  case "${VERIFY_ENV_BACKEND}" in
    compose)
      compose_cmd logs --no-color app > "${target_dir}/verify-container.log" 2>&1 || true
      compose_cmd logs --no-color db > "${target_dir}/verify-postgres.log" 2>&1 || true
      ;;
    podman)
      podman logs "${VERIFY_APP_CONTAINER_NAME}" > "${target_dir}/verify-container.log" 2>&1 || true
      podman logs "${VERIFY_DB_CONTAINER_NAME}" > "${target_dir}/verify-postgres.log" 2>&1 || true
      ;;
    *)
      echo "Unsupported verification backend: ${VERIFY_ENV_BACKEND}" >&2
      exit 1
      ;;
  esac
}

wait_for_http() {
  local ok=0
  local attempt
  for attempt in $(seq 1 10); do
    if curl --silent --show-error --fail --connect-timeout 1 --max-time 1 \
      "http://localhost:${VERIFY_CONTAINER_PORT}/login" >/dev/null; then
      ok=$((ok + 1))
      if [[ "${ok}" -ge 2 ]]; then
        return 0
      fi
    else
      ok=0
    fi
    sleep 2
  done

  print_logs
  exit 1
}

compose_up() {
  require_common_env
  if ! compose_cmd up --detach; then
    print_logs
    exit 1
  fi
}

compose_down() {
  compose_cmd down --volumes --remove-orphans >/dev/null 2>&1 || true
}

podman_wait_for_db() {
  local status=""
  local attempt
  for attempt in $(seq 1 60); do
    status="$(podman_db_health)"
    if [[ "${status}" == "healthy" ]]; then
      return 0
    fi
    if podman_db_is_running && podman_db_is_ready; then
      return 0
    fi
    sleep 1
  done

  echo "Verification database did not become healthy under Podman." >&2
  print_logs
  exit 1
}

podman_up() {
  require_common_env

  if ! podman network exists "${VERIFY_NETWORK_NAME}"; then
    podman network create "${VERIFY_NETWORK_NAME}" >/dev/null
  fi

  podman run --replace --detach \
    --name "${VERIFY_DB_CONTAINER_NAME}" \
    --network "${VERIFY_NETWORK_NAME}" \
    --publish "${VERIFY_DB_PORT}:5432" \
    --health-cmd "pg_isready --username=${VERIFY_DB_USERNAME} --dbname=${VERIFY_DB_NAME}" \
    --health-interval 1s \
    --health-timeout 5s \
    --health-retries 30 \
    -e POSTGRES_DB="${VERIFY_DB_NAME}" \
    -e POSTGRES_USER="${VERIFY_DB_USERNAME}" \
    -e POSTGRES_PASSWORD="${VERIFY_DB_PASSWORD}" \
    postgres:17 >/dev/null

  podman_wait_for_db

  if ! podman run --replace --detach \
    --name "${VERIFY_APP_CONTAINER_NAME}" \
    --network "${VERIFY_NETWORK_NAME}" \
    --publish "${VERIFY_CONTAINER_PORT}:8080" \
    --pull=never \
    -e WORTWERK_DB_URL="jdbc:postgresql://${VERIFY_DB_CONTAINER_NAME}:5432/${VERIFY_DB_NAME}" \
    -e WORTWERK_DB_USERNAME="${VERIFY_DB_USERNAME}" \
    -e WORTWERK_DB_PASSWORD="${VERIFY_DB_PASSWORD}" \
    "${VERIFY_CONTAINER_IMAGE}" >/dev/null; then
    print_logs
    exit 1
  fi
}

podman_down() {
  podman rm --force "${VERIFY_APP_CONTAINER_NAME}" "${VERIFY_DB_CONTAINER_NAME}" >/dev/null 2>&1 || true
  podman network rm "${VERIFY_NETWORK_NAME}" >/dev/null 2>&1 || true
}

case "${COMMAND}" in
  up)
    case "${VERIFY_ENV_BACKEND}" in
      compose) compose_up ;;
      podman) podman_up ;;
      *) echo "Unsupported verification backend: ${VERIFY_ENV_BACKEND}" >&2; exit 1 ;;
    esac
    ;;
  wait)
    require_common_env
    wait_for_http
    ;;
  logs)
    print_logs
    ;;
  down)
    case "${VERIFY_ENV_BACKEND}" in
      compose) compose_down ;;
      podman) podman_down ;;
      *) echo "Unsupported verification backend: ${VERIFY_ENV_BACKEND}" >&2; exit 1 ;;
    esac
    ;;
  capture-logs)
    [[ -n "${TARGET_DIR}" ]] || usage
    capture_logs "${TARGET_DIR}"
    ;;
  capture-and-down)
    [[ -n "${TARGET_DIR}" ]] || usage
    capture_logs "${TARGET_DIR}"
    case "${VERIFY_ENV_BACKEND}" in
      compose) compose_down ;;
      podman) podman_down ;;
      *) echo "Unsupported verification backend: ${VERIFY_ENV_BACKEND}" >&2; exit 1 ;;
    esac
    ;;
  *)
    usage
    ;;
esac
