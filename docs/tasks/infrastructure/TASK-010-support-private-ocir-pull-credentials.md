---
id: TASK-010
title: Support Private OCIR Pull Credentials for Runtime
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Enable OCI Container Instance runtime to pull private OCIR images using explicit registry credentials.

## Scope

- Add runtime Terraform variables for image registry credentials.
- Wire runtime Terraform resource to use OCIR image pull credentials.
- Update `deploy.sh release` to pass private registry credentials to runtime apply.
- Update deployment documentation to describe private pull configuration.

## Assumptions

- OCIR repository remains private.
- `OCI_USERNAME` and `OCI_AUTH_TOKEN` are available to release script.

## Acceptance Criteria

- [x] Runtime Terraform includes required image pull credential variables.
- [x] Container Instance resource is configured to pull private OCIR images.
- [x] `deploy.sh release` writes runtime vars for private image pull auth.
- [x] Documentation describes private registry pull behavior and required secrets.
- [x] `./mvnw clean verify` passes after changes.
