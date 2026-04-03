---
id: TASK-009
title: Automate OCI Build Push and Runtime Deploy
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-03
updated: 2026-04-03
---

## Summary

Add a script that builds the container image, pushes to OCIR, deploys runtime Terraform, and prunes old images with a safe retention policy.

## Scope

- Extend `infrastructure/oci/deploy.sh` to support release automation.
- Build and push image tagged with git commit hash (or provided tag).
- Apply runtime stack using foundation outputs.
- Add image cleanup step that keeps recent versions and removes older ones.
- Document required environment variables and usage modes.

## Assumptions

- Foundation stack has already been applied.
- OCI CLI, Docker and Terraform are available locally.
- Operator has rights to push to OCIR and manage runtime resources.

## Acceptance Criteria

- [x] Script can build and push a new image.
- [x] Script can deploy runtime stack with new image tag.
- [x] Script can prune older images using configurable retention (default keep at least 2).
- [x] Script keeps infra-only modes (`foundation`, `runtime`, `all`) available.
- [x] Documentation explains required variables and safe cleanup behavior.
- [x] `./mvnw clean verify` passes after changes.
