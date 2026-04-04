---
id: TASK-015
title: Add Stable Endpoint via OCI Load Balancer
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Provide a stable public endpoint by routing traffic through an OCI Load Balancer that uses a reserved public IP and forwards requests to the current Container Instance private IP.

## Scope

- Add foundation resources for Load Balancer networking prerequisites and reserved public IP.
- Add runtime resources for OCI Load Balancer, backend set, backend and listener.
- Point backend to the current Container Instance private IP on port `8080`.
- Update runtime outputs and docs to expose/load the stable endpoint.
- Prevent Terraform drift updates that attempt to unassign LB-managed reserved public IP bindings.

## Assumptions

- HTTP only for now (no TLS/domain in this task).
- Runtime replacement of Container Instance is acceptable as long as endpoint remains stable.

## Acceptance Criteria

- [x] Foundation outputs include reserved public IP and LB NSG identifiers.
- [x] Runtime creates LB and serves HTTP on a stable IP endpoint.
- [x] Runtime backend targets the deployed Container Instance private IP.
- [x] Deployment docs/scripts include new LB-related variables and outputs.
- [x] `./mvnw clean verify` passes after changes.
