---
id: TASK-029
title: Add tools/rollout Wrapper for OCI Rollout
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-05
updated: 2026-04-11
---

## Summary

Keep the repository-local `tools/rollout` helper aligned with the rollout contract by sourcing `~/.oci/oci.secrets.env`, ensuring local verify credentials exist for the release gate, and then running `./infrastructure/oci/deploy.sh rollout`.

## Scope

- Create executable `tools/rollout` shell wrapper.
- Validate secret file exists before sourcing and fail with a clear message if missing.
- Preserve operator-provided `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` when already set.
- Generate ephemeral local verify credentials when those variables are absent so rollout can satisfy its own `clean verify` prerequisite.
- Invoke rollout from repo root so it works from any current working directory.
- Document usage in OCI runbook.

## Out of Scope

- Changing OCI Terraform resources.
- Replacing `infrastructure/oci/deploy.sh`.

## Acceptance Criteria

- [x] Running `./tools/rollout` sources `~/.oci/oci.secrets.env`, ensures verify credentials exist, and triggers rollout.
- [x] Explicit `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` values are preserved.
- [x] Script exits with actionable error if secrets file is missing.
- [x] Script is executable.
- [x] `./mvnw clean verify` passes after changes.
