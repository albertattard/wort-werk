---
id: TASK-048
title: Introduce Least-Privilege OCI Runtime DB Role
status: done
category: infrastructure
related_features:
  - SPEC-008
owner: @aattard
created: 2026-04-12
updated: 2026-04-12
---

## Summary

Replace the OCI runtime database credential model that currently defaults to `wortwerk_admin` with a dedicated non-admin application role whose privileges are limited to Wort-Werk-owned database/schema responsibilities.

## Scope

- Define the runtime DB role boundary required by the current application and Flyway usage.
- Stop defaulting `runtime_db_username` to the PostgreSQL administrator user.
- Update secret bootstrap flow so runtime credentials are managed independently from administrator credentials.
- Add or document the privileged bootstrap path required to create the runtime role and grant its privileges.
- Update OCI docs and runtime contract to distinguish administrator credentials from application credentials.

## Security Constraints

- Runtime database access must not use the PostgreSQL administrator account.
- Runtime credentials must remain in OCI Vault rather than repository-tracked files.
- The least-privilege role should be limited to Wort-Werk-owned database/schema activity, not broader instance administration.
- Any privileged bootstrap path needed to create roles or grants must be explicit and documented rather than hidden in ad hoc operator steps.

## Architecture Notes

- Because Flyway currently uses the application datasource, the runtime role still needs enough privilege to manage Wort-Werk-owned schema changes.
- That still represents a material security improvement over using the PostgreSQL administrator account.
- A stronger future split between migration credentials and runtime credentials remains possible, but it is not assumed in this task.

## Out of Scope

- Replacing Flyway with a different migration tool.
- Requiring a separate migration execution platform in this task unless the implementation proves it is unavoidable.
- Non-OCI production environments.

## Acceptance Criteria

- [x] `runtime_db_username` no longer defaults to `wortwerk_admin`.
- [x] Secret bootstrap workflow no longer aliases runtime credentials to the administrator password by default.
- [x] Repository docs describe how the least-privilege runtime role is provisioned and rotated.
- [x] The runtime DB role boundary is explicit and limited to application-owned responsibilities.
- [x] `./mvnw clean verify` passes after changes.
