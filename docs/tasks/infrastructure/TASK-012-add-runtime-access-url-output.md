---
id: TASK-012
title: Add Runtime Access URL Output
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Expose runtime Terraform outputs for public IP and direct HTTP URL so operators can access the deployed app without manual OCI CLI lookup.

## Scope

- Add runtime output for container instance public IP.
- Add runtime output for app access URL (`http://<ip>:8080`).
- Update runtime docs to include the new outputs.

## Assumptions

- Runtime container uses public IP assignment.
- Application listens on port `8080`.

## Acceptance Criteria

- [x] `terraform output` includes `public_ip`.
- [x] `terraform output` includes `access_url`.
- [x] Runtime README documents the new outputs.
- [x] `./mvnw clean verify` passes after changes.
