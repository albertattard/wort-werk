---
id: TASK-038
title: Adopt PostgreSQL-only Verification and DB Test Tag
status: completed
category: repo-process
related_features:
  - SPEC-005
  - SPEC-006
owner: @aattard
created: 2026-04-10
updated: 2026-04-10
---

## Summary

Remove H2 from the verification/runtime path, introduce a dedicated `@Tag("db")` category for PostgreSQL-backed JVM tests, and keep `./mvnw clean verify` as the single DB-backed verification command.

## Scope

- Add a dedicated `@Tag("db")` convention for PostgreSQL-backed JVM tests.
- Configure Surefire to exclude both `db` and `e2e` tests.
- Configure Failsafe to run both `db` and `e2e` tests.
- Provision PostgreSQL for verification and run the application container against it.
- Remove H2 from the application runtime/verification path.
- Align workflow docs and conventions with the new test taxonomy.

## Out of Scope

- Rewriting Playwright tests in another framework.
- Adding progress/attempt tracking.
- Introducing a second database engine for tests.

## Acceptance Criteria

- [x] `@Tag("db")` is documented and available for PostgreSQL-backed JVM tests.
- [x] `./mvnw test` does not run `db` or `e2e` tests.
- [x] `./mvnw clean verify` provisions PostgreSQL and runs both `db` and `e2e` tests.
- [x] Verification no longer depends on H2.
- [x] Workflow docs (`README.md`, `AGENTS.md`, task/spec indexes) reflect the new taxonomy.
- [x] `./mvnw clean verify` passes.
