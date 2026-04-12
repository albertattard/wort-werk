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

Expose runtime Terraform outputs for the public entrypoint IP and access URL so operators can access the deployed app without manual OCI CLI lookup.

## Scope

- Add runtime output for the public Load Balancer IP.
- Add runtime output for the application access URL.
- Update runtime docs to include the new outputs.

## Assumptions

- The stable public entrypoint is the Load Balancer.
- Application traffic is routed through the Load Balancer listener.

## Acceptance Criteria

- [x] `terraform output` includes `public_ip`.
- [x] `terraform output` includes `access_url`.
- [x] Runtime README documents the new outputs.
- [x] `./mvnw clean verify` passes after changes.
