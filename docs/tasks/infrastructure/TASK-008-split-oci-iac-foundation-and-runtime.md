---
id: TASK-008
title: Split OCI IaC into Foundation and Runtime Stacks
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-03
updated: 2026-04-03
---

## Summary

Refactor OCI Terraform into two stacks so environment setup and release rollout are decoupled.

## Scope

- Create `infrastructure/oci/foundation` stack for shared infrastructure.
- Create `infrastructure/oci/runtime` stack for Container Instance deployment.
- Wire runtime stack inputs from foundation outputs.
- Ensure runtime image is parameterized by `image_repository` + immutable `image_tag`.
- Update deployment runbook with two-phase apply workflow.

## Assumptions

- Operator runs Terraform with tenancy-level admin permissions.
- OCI profile/region alignment is handled in CLI configuration.
- Runtime image tag is provided at release time (git commit hash preferred).

## Acceptance Criteria

- [x] Foundation stack exists and provisions compartment, networking and OCIR repository.
- [x] Runtime stack exists and provisions Container Instance only.
- [x] Runtime stack accepts `image_repository` and `image_tag` instead of static image URL.
- [x] Documentation shows first-time flow (foundation + runtime) and release flow (runtime only).
- [x] Documentation includes OCIR namespace retrieval command.
- [x] `./mvnw clean verify` passes after changes.
