---
id: TASK-020
title: Reduce Deploy 502 with Overlap and Readiness Health Checks
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-12
---

## Summary

Reduce transient 502 responses during runtime image rollouts by overlapping backend replacement and using Spring Actuator readiness on a dedicated management port.

## Scope

- Configure runtime Container Instance replacement with `create_before_destroy`.
- Configure LB backend replacement with `create_before_destroy` to avoid removing old backend first.
- Expose Spring Actuator health on a dedicated management port.
- Use Actuator readiness for backend health checks instead of a learner-facing route.
- Keep the management port reachable from the Load Balancer but not exposed through a public listener.
- Update deployment docs to reflect mitigation behavior and residual limitations.

## Assumptions

- Health-check path must stay unauthenticated even if learner-facing routes later require login.
- Database readiness must contribute to backend readiness because the app cannot serve auth-backed traffic without PostgreSQL.
- Single-instance architecture remains in place for now (not full blue/green with manual cutover gates).

## Acceptance Criteria

- [x] Runtime Terraform keeps previous Container Instance during replacement creation.
- [x] Runtime Terraform keeps previous LB backend until replacement backend is created.
- [x] Runtime exposes Spring Actuator health on a dedicated management port.
- [x] LB backend health checks target Actuator readiness and remain healthy after auth is enabled.
- [x] Database health contributes to the readiness result used by OCI.
- [x] OCI docs explain the management-port and readiness design.
- [x] `./mvnw clean verify` passes after changes.
