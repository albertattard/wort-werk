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

Document and prepare the deployment path for Wort-Werk on OCI using OCIR and Container Instances, including infrastructure as code.

## Scope

- Define OCIR image push workflow.
- Define OCI Container Instance deployment workflow.
- Document required networking/security settings.
- Document update rollout for new image versions.
- Document optional OCI Load Balancer + TLS step.
- Add IaC definitions for core OCI resources required by this deployment.

## Target OCI Resources

Core (required in this task):
- Compartment (existing or dedicated)
- VCN
- Subnet for Container Instance
- NSG or Security List rules
- Internet Gateway (or equivalent egress path)
- OCIR repository
- Container Instance
- IAM policies for push/deploy operations

Optional (not required for initial testing):
- OCI Load Balancer
- TLS certificate
- DNS record
- OCI monitoring/alarms

## Assumptions

- Container image already includes `assets/`.
- Single service deployment is sufficient in this phase.
- IaC tool will be Terraform unless later decided otherwise.

## Acceptance Criteria

- [ ] Deployment runbook exists under `container/` (or equivalent) and is actionable.
- [ ] Runbook includes OCIR authentication and image push steps.
- [ ] Runbook includes OCI Container Instance create/update steps.
- [ ] Runbook includes ingress/security checklist.
- [ ] IaC files exist for core OCI resources (at minimum: Container Instance and networking prerequisites).
- [ ] IaC scope explicitly lists required vs optional OCI resources.
- [ ] Scope limitations (no DB, no OKE) are stated.
- [ ] `./mvnw clean verify` passes after documentation updates.
