---
id: SPEC-003
title: OCI Deployment via Container Instance
status: done
priority: medium
owner: @aattard
last_updated: 2026-04-12
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
- `foundation`: compartment, VCN, subnet, NSG, route table, internet gateway, OCIR repository, reserved public IP for Load Balancer
- `runtime`: Container Instance + public Load Balancer, parameterized by `image_repository` + `image_tag`

TLS model:
- Terraform manages LB and network wiring.
- Let's Encrypt certificate/private key material is sourced from project-local certificate files and managed by Terraform.
- HTTPS is always enabled in runtime Terraform (no HTTP-only mode).

Expected lifecycle:
- foundation apply: infrequent (environment setup/change)
- runtime apply: frequent (release/update/rollback)

Repeatable operator flow:
- one command should support a full end-to-end rollout by running `foundation` then `release` (`release` includes runtime apply after image publication)
- this flow is the recommended repeatable path when operators want deterministic refresh + deploy behavior
- rollout should fail fast when the workspace has pending changes outside `assets/images/new`, unless explicitly overridden for exceptional runs
- a repository-local wrapper command should exist so operators can run rollout without manually typing environment bootstrap + deploy invocation
- the rollout wrapper must ensure local verify credentials exist for the release-stage `./mvnw clean verify` gate, while preserving any explicit operator-provided values
- runtime apply in repeatable rollout must not fail on missing `image_tag`; it should reuse the currently deployed runtime image tag unless a new tag is explicitly provided
- load balancer health checks must target a stable unauthenticated route so auth changes do not strand an otherwise healthy backend behind `502`

## Acceptance Criteria

- [x] Deployment documentation exists for OCIR push + OCI Container Instance run.
- [x] Deployment docs include networking and ingress requirements.
- [x] Deployment docs include update strategy for new image versions.
- [x] Deployment docs include optional load balancer/TLS step.
- [x] Deployment docs include a concrete Let’s Encrypt manual issuance and manual 90-day renewal runbook.
- [x] Runtime Terraform manages OCI LB certificate, HTTPS listener and HTTP to HTTPS redirect.
- [x] Runtime docs define project-local certificate file paths consumed by Terraform.
- [x] Runtime Terraform assumes TLS is mandatory and always configures HTTPS + HTTP to HTTPS redirect.
- [x] Foundation networking allows public ingress to both HTTP (`80`) and HTTPS (`443`) listener ports on the Load Balancer.
- [x] Infrastructure is defined as code (IaC) for core OCI deployment resources.
- [x] Infrastructure is split into foundation/runtime stacks.
- [x] Runtime stack consumes foundation outputs and deploys by immutable image tag.
- [x] Repository includes deployment script that builds, pushes and applies runtime stack.
- [x] Deployment script supports safe image cleanup policy (retention-based) instead of deleting all previous images.
- [x] Deployment script cleanup does not fail a successful runtime deployment if repository lookup is unavailable.
- [x] Runtime supports private OCIR image pulls via explicit registry credentials.
- [x] Runtime outputs include direct HTTP access details (public IP and URL) after deploy.
- [x] Deployment exposes a stable public endpoint through OCI Load Balancer with reserved public IP.
- [x] Runtime deploy strategy minimizes 502 windows by keeping old backend alive until replacement backend is registered.
- [x] Load balancer health checks use HTTP readiness instead of raw TCP to reduce premature traffic routing.
- [x] Release automation executes `./mvnw clean verify`, then publishes a multi-architecture (`linux/amd64,linux/arm64`) image tag before runtime apply.
- [x] Deployment script provides a single repeatable command that runs `foundation -> release` in order, where `release` performs runtime apply after publishing the image.
- [x] Rollout preflight blocks deployment when git working tree is dirty outside `assets/images/new`, with an explicit override knob for intentional exceptions.
- [x] Repository includes `tools/rollout` wrapper that sources OCI secrets file, ensures verify credentials exist, and triggers `deploy.sh rollout`.
- [x] Runtime stage resolves `image_tag` automatically (existing deployed tag) when not explicitly provided, and only fails when no prior runtime tag exists.
- [x] Scope explicitly excludes database and Kubernetes/OKE.

## Non-goals

- Kubernetes (OKE) deployment.
- Database provisioning and migration.
