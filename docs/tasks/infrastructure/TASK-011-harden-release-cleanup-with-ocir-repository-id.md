---
id: TASK-011
title: Harden Release Cleanup with OCIR Repository ID
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Make release image cleanup reliable by sourcing OCIR repository ID from foundation outputs and preventing cleanup lookup failures from failing an otherwise successful deployment.

## Scope

- Add `ocir_repository_id` foundation output.
- Update `deploy.sh release` cleanup logic to use repository ID first.
- Keep cleanup best-effort: warn and continue if repository resolution fails.
- Update OCI deployment documentation.

## Assumptions

- Foundation stack has already been applied and includes OCIR repository state.
- Runtime deployment success is higher priority than cleanup pruning.

## Acceptance Criteria

- [x] Foundation exposes `ocir_repository_id` output.
- [x] Release cleanup uses repository ID when available.
- [x] Release command does not fail solely because cleanup repository lookup is empty.
- [x] OCI deployment docs reflect cleanup behavior.
- [x] `./mvnw clean verify` passes after changes.
