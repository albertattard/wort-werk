---
id: TASK-020
title: Reduce Deploy 502 with Overlap and Readiness Health Checks
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Reduce transient 502 responses during runtime image rollouts by overlapping backend replacement and switching load balancer health checks from TCP to HTTP readiness.

## Scope

- Configure runtime Container Instance replacement with `create_before_destroy`.
- Configure LB backend replacement with `create_before_destroy` to avoid removing old backend first.
- Use HTTP health checks (`/`) with expected 200 status for backend readiness.
- Update deployment docs to reflect mitigation behavior and residual limitations.

## Assumptions

- Application root path (`/`) returns HTTP 200 when ready to serve traffic.
- Single-instance architecture remains in place for now (not full blue/green with manual cutover gates).

## Acceptance Criteria

- [x] Runtime Terraform keeps previous Container Instance during replacement creation.
- [x] Runtime Terraform keeps previous LB backend until replacement backend is created.
- [x] LB backend set uses HTTP health checks with readiness semantics.
- [x] Docs explain mitigation and remaining risk for single-instance rollouts.
- [x] `./mvnw clean verify` passes after changes.
