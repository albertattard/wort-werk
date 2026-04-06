---
id: TASK-030
title: Resolve Runtime image_tag Automatically in Rollout
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-05
updated: 2026-04-06
---

## Summary

Fix rollout/runtime Terraform input handling so `image_tag` is automatically resolved from current runtime state when no explicit tag is supplied.

## Scope

- Update `infrastructure/oci/deploy.sh` runtime stage to always provide `image_tag`.
- Resolution order:
  1. `IMAGE_TAG` environment variable (if provided)
  2. existing value in `runtime/release.auto.tfvars` (if present)
  3. current runtime Terraform output `deployed_image_url` tag (if state exists)
- Fail with actionable error when no prior tag exists and no explicit tag is provided.
- Document behavior in `infrastructure/oci/README.md`.

## Out of Scope

- Changing Terraform runtime resources.
- Changing release image publish/tag logic.

## Acceptance Criteria

- [x] `deploy.sh runtime` no longer fails with missing `image_tag` when a prior runtime deployment exists.
- [x] `deploy.sh rollout` runs `foundation -> runtime -> release` without `image_tag` prompt/error in normal existing-environment operation.
- [x] Script provides clear error when first-time runtime apply needs `image_tag`.
- [x] `./mvnw clean verify` passes after changes.
