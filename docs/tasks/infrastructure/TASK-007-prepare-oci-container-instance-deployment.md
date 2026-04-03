---
id: TASK-007
title: Prepare OCI Container Instance Deployment
status: pending
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-03
updated: 2026-04-03
---

## Summary

Document and prepare the deployment path for Wort-Werk on OCI using OCIR and Container Instances.

## Scope

- Define OCIR image push workflow.
- Define OCI Container Instance deployment workflow.
- Document required networking/security settings.
- Document update rollout for new image versions.
- Document optional OCI Load Balancer + TLS step.

## Assumptions

- Container image already includes `assets/`.
- Single service deployment is sufficient in this phase.
- Manual deployment steps are acceptable before automation.

## Acceptance Criteria

- [ ] Deployment runbook exists under `container/` (or equivalent) and is actionable.
- [ ] Runbook includes OCIR authentication and image push steps.
- [ ] Runbook includes OCI Container Instance create/update steps.
- [ ] Runbook includes ingress/security checklist.
- [ ] Scope limitations (no DB, no OKE) are stated.
- [ ] `./mvnw clean verify` passes after documentation updates.
