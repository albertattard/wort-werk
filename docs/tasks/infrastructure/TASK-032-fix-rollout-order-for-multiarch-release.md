---
id: TASK-032
title: Fix Rollout Order for Multi-Arch Release
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-06
updated: 2026-04-06
---

## Summary

Fix rollout sequencing so runtime apply never happens before the release image is published, preventing architecture mismatch failures during rollout.

## Scope

- Update `deploy.sh rollout` flow to run `foundation` then `release`.
- Keep standalone `runtime` mode available for manual runtime-only applies.
- Update deployment docs/spec wording to reflect the corrected rollout sequence.

## Out of Scope

- Changing runtime Terraform resources.
- Changing release verification or multi-arch publish implementation.

## Acceptance Criteria

- [x] `deploy.sh rollout` no longer runs `runtime` before `release`.
- [x] Rollout docs describe `foundation -> release` sequencing.
- [x] `./mvnw clean verify` passes after changes.
