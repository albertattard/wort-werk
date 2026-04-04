---
id: SPEC-003
title: OCI Deployment via Container Instance
status: done
priority: medium
owner: @aattard
last_updated: 2026-04-04
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
- Foundation infrastructure configuration (compartment/network/OCIR)
- Runtime image metadata (repository + immutable image tag)

Output:
- reusable foundation stack
- runtime stack for Container Instance rollout
- running Wort-Werk instance in OCI Container Instances
- documented deployment flow and operational update path
- scripted build/push/runtime deployment flow aligned to IaC

## Deployment Model

Two-stack Terraform model:
- `foundation`: compartment, VCN, subnet, NSG, route table, internet gateway, OCIR repository
- `runtime`: Container Instance only, parameterized by `image_repository` + `image_tag`

Expected lifecycle:
- foundation apply: infrequent (environment setup/change)
- runtime apply: frequent (release/update/rollback)

## Acceptance Criteria

- [x] Deployment documentation exists for OCIR push + OCI Container Instance run.
- [x] Deployment docs include networking and ingress requirements.
- [x] Deployment docs include update strategy for new image versions.
- [x] Deployment docs include optional load balancer/TLS step.
- [x] Infrastructure is defined as code (IaC) for core OCI deployment resources.
- [x] Infrastructure is split into foundation/runtime stacks.
- [x] Runtime stack consumes foundation outputs and deploys by immutable image tag.
- [x] Repository includes deployment script that builds, pushes and applies runtime stack.
- [x] Deployment script supports safe image cleanup policy (retention-based) instead of deleting all previous images.
- [x] Deployment script cleanup does not fail a successful runtime deployment if repository lookup is unavailable.
- [x] Runtime supports private OCIR image pulls via explicit registry credentials.
- [x] Scope explicitly excludes database and Kubernetes/OKE.

## Non-goals

- Kubernetes (OKE) deployment.
- Database provisioning and migration.
