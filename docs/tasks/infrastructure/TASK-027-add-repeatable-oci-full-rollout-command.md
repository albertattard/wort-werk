---
id: TASK-027
title: Add Repeatable OCI Full Rollout Command
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-06
updated: 2026-04-06
---

## Summary

Add one repeatable deployment command that executes `foundation`, then `runtime`, then `release` so operators can run a deterministic full OCI rollout without manually chaining multiple commands.

## Scope

- Extend `infrastructure/oci/deploy.sh` with a dedicated mode that runs `foundation -> runtime -> release` sequentially.
- Keep existing single-stage modes (`foundation`, `runtime`, `release`) unchanged.
- Document the new mode in `infrastructure/oci/README.md` with copy/paste usage.

## Out of Scope

- Reworking Terraform resource topology.
- Replacing existing `deploy.sh release` verification/push behavior.

## Acceptance Criteria

- [x] `deploy.sh` supports a single mode that runs `foundation`, then `runtime`, then `release`.
- [x] The sequence is documented as the repeatable full rollout path.
- [x] Existing stage-specific modes continue to work.
- [x] `./mvnw clean verify` passes after changes.
