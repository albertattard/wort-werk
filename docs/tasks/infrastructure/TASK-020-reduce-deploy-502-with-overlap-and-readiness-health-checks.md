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

Reduce transient 502 responses during runtime image rollouts by overlapping backend replacement and using an HTTP health-check path that remains reachable after authentication changes.

## Scope

- Configure runtime Container Instance replacement with `create_before_destroy`.
- Configure LB backend replacement with `create_before_destroy` to avoid removing old backend first.
- Use HTTP health checks on a stable unauthenticated path with expected 200 status for backend readiness.
- Update deployment docs to reflect mitigation behavior and residual limitations.

## Assumptions

- Health-check path must stay unauthenticated even if learner-facing routes later require login.
- Single-instance architecture remains in place for now (not full blue/green with manual cutover gates).

## Acceptance Criteria

- [x] Runtime Terraform keeps previous Container Instance during replacement creation.
- [x] Runtime Terraform keeps previous LB backend until replacement backend is created.
- [x] LB backend set uses an HTTP health-check path that still returns 200 after authentication is enabled.
- [x] Docs explain the chosen health-check path and the auth-related constraint.
- [x] `./mvnw clean verify` passes after changes.
