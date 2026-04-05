---
id: TASK-028
title: Enforce Clean Worktree for OCI Rollout
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Protect repeatable OCI rollout from accidental dirty-worktree deployments by failing `deploy.sh rollout` when pending changes exist outside `assets/images/new`.

## Scope

- Add rollout preflight check in `infrastructure/oci/deploy.sh`.
- Allow explicit override for exceptional runs (`ALLOW_DIRTY_ROLLOUT=true`).
- Document the behavior and override in `infrastructure/oci/README.md`.

## Out of Scope

- Blocking `foundation`, `runtime`, or `release` standalone modes.
- Enforcing commit creation.

## Acceptance Criteria

- [x] `deploy.sh rollout` fails if git reports pending changes outside `assets/images/new`.
- [x] Failure output shows offending paths and how to override intentionally.
- [x] `ALLOW_DIRTY_ROLLOUT=true` bypasses only this preflight.
- [x] `./mvnw clean verify` passes after changes.
