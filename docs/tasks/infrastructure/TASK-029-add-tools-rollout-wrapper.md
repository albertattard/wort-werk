---
id: TASK-029
title: Add tools/rollout Wrapper for OCI Rollout
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Add a repository-local `tools/rollout` helper that sources `~/.oci/oci.secrets.env` and runs `./infrastructure/oci/deploy.sh rollout`.

## Scope

- Create executable `tools/rollout` shell wrapper.
- Validate secret file exists before sourcing and fail with a clear message if missing.
- Invoke rollout from repo root so it works from any current working directory.
- Document usage in OCI runbook.

## Out of Scope

- Changing OCI Terraform resources.
- Replacing `infrastructure/oci/deploy.sh`.

## Acceptance Criteria

- [x] Running `./tools/rollout` sources `~/.oci/oci.secrets.env` and triggers rollout.
- [x] Script exits with actionable error if secrets file is missing.
- [x] Script is executable.
- [x] `./mvnw clean verify` passes after changes.
