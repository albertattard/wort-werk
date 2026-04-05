---
id: TASK-026
title: Enforce clean verify Before OCI Release
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Ensure OCI release automation runs `./mvnw clean verify`, then re-tags and pushes the verified local image so deployments cannot proceed with stale or unverified artifacts.

## Scope

- Update `infrastructure/oci/deploy.sh` release mode to execute `./mvnw clean verify`.
- Re-tag the verified local image to the OCIR release tag and push it.
- Fail release immediately when verification fails.
- Document this behavior in OCI release runbook.

## Assumptions

- Operator runs release from a workspace that contains the project and Maven wrapper.
- Release runtime re-tags and pushes the verified local image after verification passes.

## Acceptance Criteria

- [x] `deploy.sh release` runs `./mvnw clean verify` before retag/push.
- [x] `deploy.sh release` re-tags and pushes the verified local image instead of building a second image.
- [x] Release stops if `clean verify` fails.
- [x] OCI README documents the pre-release verification step.
- [x] `./mvnw clean verify` passes after changes.
