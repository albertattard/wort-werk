---
id: SPEC-006
title: Container-First Verification Workflow
status: done
priority: high
owner: @aattard
last_updated: 2026-04-14
---

## Problem

Current verification targets the production container image built from current source, but the orchestration inside Maven is still expressed through multiple low-level Docker commands. The desired workflow keeps `./mvnw clean verify` as the contract while simplifying environment orchestration.

## Goal

Define one primary pre-commit workflow where `./mvnw clean verify` validates a freshly built container image with the existing Playwright e2e tests and any database-backed integration tests against PostgreSQL, while repository-owned verification helpers select a compatible container orchestration backend for the current execution environment.

## Required Order

1. Ensure verification DB credentials are present in the environment:
   - `export VERIFY_DB_USERNAME='<username>'`
   - `export VERIFY_DB_PASSWORD='<password>'`
2. Run Maven verification:
   - `./mvnw clean verify`
3. During `verify`, Maven must execute:
   1. build a local single-platform container image from current workspace code,
   2. start the verification environment through the repository-owned verification helper using that exact image tag,
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
- Keep OCI DevOps verification daemonless; managed runners must not depend on a Docker daemon socket in order to execute `./mvnw clean verify`.
- Repository-owned verification helper scripts must choose the correct orchestration backend explicitly instead of embedding runner-specific container commands directly inside Maven plugin XML.
- OCI DevOps verification must use a Podman-native backend that is compatible with the managed runner environment.
- OCI DevOps verification readiness must not rely solely on container health-state metadata when managed runners can report delayed or missing health transitions; repository helpers must actively confirm PostgreSQL readiness before failing the run.
- OCI DevOps verification runners must provision the Playwright browser runtime dependencies required for the repository e2e suite before `./mvnw clean verify` starts the browser-backed tests.
- Oracle Linux OCI runners must install browser host packages through the native RPM package manager instead of relying on Playwright's Ubuntu-only `apt-get` fallback.
- OCI DevOps image publication must use runner-compatible build tooling instead of assuming the managed OCI surface behaves like a full local Docker Buildx installation.
- OCI DevOps build scripts should detect whether the runner exposes `docker buildx create`, inline publication flags, or Podman-style manifest publication and only use the capabilities that are actually present on the managed runner.
- Let Compose service naming provide container-to-container hostnames inside the verification stack; avoid redundant environment variables for values Compose can derive directly.
- Keep verification DB credentials out of the repository; `verify` must read them from environment variables and fail fast if they are missing.
- Treat `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` as explicit prerequisites in workflow documentation, not hidden assumptions.
- Keep any optional registry publishing credentials out of the repository; `verify` itself must not require a separate Oracle base-image registry login when using the Oracle no-fee verification image path.
- Repository automation and tests that exercise operator helper scripts must not block on interactive secret prompts during `./mvnw test` or `./mvnw clean verify`; automated invocations must fail fast with an explicit non-interactive error instead.
- Do not use a dedicated Spring profile purely to select the only supported database; single-database datasource settings belong in the base application configuration.
- Keep registry publishing out of `verify`; image publication belongs to release automation.
- Keep `./mvnw test` limited to fast tests that do not require PostgreSQL.

## Acceptance Criteria

- [x] Repository docs define `./mvnw clean verify` as the container e2e gate.
- [x] `verify` builds a fresh local single-platform image from current code and does not rely on stale tags.
- [x] `verify` provisions PostgreSQL and runs DB-backed tests and Playwright e2e against that environment via Docker Compose.
- [x] `./mvnw test` excludes both `@Tag("db")` and `@Tag("e2e")`.
- [x] `verify` starts/stops the verification environment through repository-owned helpers after tests.
- [ ] OCI DevOps verification environments use a Podman-native backend and do not require a Docker daemon socket.
- [ ] OCI DevOps verification waits for PostgreSQL readiness using a runner-compatible probe instead of depending only on Podman health status.
- [ ] OCI DevOps verification provisions the Playwright browser runtime dependencies needed by the e2e suite before Maven verify runs on the managed runner.
- [ ] OCI DevOps verification installs browser host packages on Oracle Linux through repository-tracked RPM commands rather than Playwright's Ubuntu fallback helpers.
- [ ] OCI DevOps image publication avoids runner-incompatible `docker buildx` subcommands and can publish the runtime image from the managed runner.
- [ ] OCI DevOps publish scripts adapt to the managed runner's available build subcommands and publication modes instead of assuming builder-bootstrap or inline push support.
- [x] The Compose-managed app uses the `db` service hostname directly for database connectivity instead of a redundant injected Compose JDBC URL variable.
- [x] `verify` reads DB verification credentials from environment variables rather than repository-stored defaults.
- [x] Workflow docs show `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` as explicit prerequisites before `./mvnw clean verify`.
- [x] Automated tests covering helper scripts fail fast rather than prompting on `/dev/tty` during Maven verification.
- [x] The single supported PostgreSQL datasource is configured without a dedicated database-selection Spring profile.
- [x] `verify` does not push images to any remote registry.
- [ ] The repository contains a testable verification-helper boundary instead of duplicating orchestration commands across Maven exec blocks.
- [x] Current workflow docs are aligned (no conflicting mandatory gate language).
