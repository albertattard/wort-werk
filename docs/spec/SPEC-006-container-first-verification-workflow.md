---
id: SPEC-006
title: Container-First Verification Workflow
status: done
priority: high
owner: @aattard
last_updated: 2026-04-12
---

## Problem

Current verification targets the production container image built from current source, but the orchestration inside Maven is still expressed through multiple low-level Docker commands. The desired workflow keeps `./mvnw clean verify` as the contract while simplifying environment orchestration.

## Goal

Define one primary pre-commit workflow where `./mvnw clean verify` validates a freshly built container image with the existing Playwright e2e tests and any database-backed integration tests against PostgreSQL, while Docker Compose owns local verification environment orchestration.

## Required Order

1. Ensure verification DB credentials are present in the environment:
   - `export VERIFY_DB_USERNAME='<username>'`
   - `export VERIFY_DB_PASSWORD='<password>'`
2. Run Maven verification:
   - `./mvnw clean verify`
3. During `verify`, Maven must execute:
   1. build a local single-platform container image from current workspace code,
   2. start the verification environment through Docker Compose using that exact image tag,
   3. provision PostgreSQL for verification,
   4. run the application container against PostgreSQL,
   5. run tagged database integration tests and Playwright e2e against that environment,
   6. capture current-run container logs during post-test cleanup when diagnostics are needed,
   7. stop/remove the verification environment.
4. Commit only when all above steps pass.

## Freshness Guarantee

- `verify` must not test a stale image tag.
- Image tag should be unique per build (recommended: current git commit SHA).
- The same generated tag must be used for both `docker run` and e2e target wiring.

## Scope

- Reuse existing Playwright Java e2e coverage.
- Introduce a dedicated `@Tag("db")` category for JVM tests that require PostgreSQL.
- Do not create a separate test framework.
- Keep commands documented and copy-paste ready.
- Keep `./mvnw clean verify` as the single command for container-based DB-backed and e2e verification.
- Use Docker Compose to describe and orchestrate the local verification stack.
- Let Compose service naming provide container-to-container hostnames inside the verification stack; avoid redundant environment variables for values Compose can derive directly.
- Keep verification DB credentials out of the repository; `verify` must read them from environment variables and fail fast if they are missing.
- Treat `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` as explicit prerequisites in workflow documentation, not hidden assumptions.
- Repository automation and tests that exercise operator helper scripts must not block on interactive secret prompts during `./mvnw test` or `./mvnw clean verify`; automated invocations must fail fast with an explicit non-interactive error instead.
- Do not use a dedicated Spring profile purely to select the only supported database; single-database datasource settings belong in the base application configuration.
- Keep registry publishing out of `verify`; image publication belongs to release automation.
- Keep `./mvnw test` limited to fast tests that do not require PostgreSQL.

## Acceptance Criteria

- [x] Repository docs define `./mvnw clean verify` as the container e2e gate.
- [x] `verify` builds a fresh local single-platform image from current code and does not rely on stale tags.
- [x] `verify` provisions PostgreSQL and runs DB-backed tests and Playwright e2e against that environment via Docker Compose.
- [x] `./mvnw test` excludes both `@Tag("db")` and `@Tag("e2e")`.
- [x] `verify` starts/stops the verification environment through Docker Compose after tests.
- [x] The Compose-managed app uses the `db` service hostname directly for database connectivity instead of a redundant injected Compose JDBC URL variable.
- [x] `verify` reads DB verification credentials from environment variables rather than repository-stored defaults.
- [x] Workflow docs show `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` as explicit prerequisites before `./mvnw clean verify`.
- [x] Automated tests covering helper scripts fail fast rather than prompting on `/dev/tty` during Maven verification.
- [x] The single supported PostgreSQL datasource is configured without a dedicated database-selection Spring profile.
- [x] `verify` does not push images to any remote registry.
- [x] Current workflow docs are aligned (no conflicting mandatory gate language).
