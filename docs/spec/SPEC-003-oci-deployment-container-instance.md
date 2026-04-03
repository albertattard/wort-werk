---
id: SPEC-003
title: OCI Deployment via Container Instance
status: in_progress
priority: medium
owner: @aattard
last_updated: 2026-04-03
---

## Problem

The application needs a practical deployment target on Oracle Cloud Infrastructure (OCI) without introducing unnecessary orchestration complexity.

## User-facing Behavior

The application is deployable to OCI from a published container image in OCIR and can be reached over HTTP/HTTPS.

Deployment should support the current architecture:
- single application container
- bundled `assets/` in image
- no database dependency yet

## Inputs/Outputs

Input:
- built/pushed container image in OCIR
- OCI network + runtime configuration

Output:
- running Wort-Werk instance in OCI Container Instances
- documented deployment flow and operational update path
- infrastructure as code definition for OCI deployment resources

## Acceptance Criteria

- [ ] Deployment documentation exists for OCIR push + OCI Container Instance run.
- [ ] Deployment docs include networking and ingress requirements.
- [ ] Deployment docs include update strategy for new image versions.
- [ ] Deployment docs include optional load balancer/TLS step.
- [ ] Infrastructure is defined as code (IaC) for core OCI deployment resources.
- [ ] Scope explicitly excludes database and Kubernetes/OKE.

## Non-goals

- Kubernetes (OKE) deployment.
- Database provisioning and migration.
