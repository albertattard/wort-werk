---
id: SPEC-003
title: OCI Deployment via Container Instance
status: done
priority: medium
owner: @aattard
last_updated: 2026-04-16
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
- Let's Encrypt certificate/private key material is issued or renewed outside Terraform, then stored in OCI-managed secrets that runtime Terraform reads at apply time.
- HTTPS is always enabled in runtime Terraform (no HTTP-only mode).

Expected lifecycle:
- foundation apply: infrequent (environment setup/change)
- runtime apply: frequent (release/update/rollback)

Repeatable operator flow:
- OCI DevOps is the recommended repeatable release path for normal production rollout
- operators should trigger a release from an explicit git reference through `infrastructure/oci/devops/run-release.sh`
- laptop-local helper scripts may still exist for targeted infrastructure administration, but they are not the source of truth for verified image publication
- OCI DevOps build environments used for normal release publication must provide a Java 25 toolchain compatible with the repository baseline, even when the managed runner default is older
- OCI DevOps deployment shell stages must provision the PostgreSQL client tooling required by repository-owned private DB bootstrap scripts instead of assuming `psql` is already present on the managed shell host
- Production and verification container builds must use Oracle-distributed technologies for the Java runtime and Linux base image
- The verification image path should prefer Oracle no-fee container images that remain anonymously pullable so local verification and OCI DevOps verification do not depend on a separate Oracle base-image registry login
- OCI DevOps-driven runtime apply must not depend on project-local TLS files; HTTPS certificate inputs must come from OCI-managed secret sources the deploy runner can read reproducibly
- runtime apply in repeatable rollout must not fail on missing `image_tag`; it should reuse the currently deployed runtime image tag unless a new tag is explicitly provided
- load balancer health checks must target a stable unauthenticated route so auth changes do not strand an otherwise healthy backend behind `502`
- production health checks should use a dedicated Spring Actuator management endpoint rather than a learner-facing UI route
- runtime container instances must not be directly internet-addressable; public ingress must terminate at the OCI Load Balancer
- runtime networking must preserve private access to required OCI regional services so startup dependencies such as Vault-backed secret reads still work without a container public IP
- the default production runtime container shape should remain the currently proven AMD64 OCI Container Instance shape until the target OCI region has a repeatable Arm-capacity-safe rollout path; Arm shape selection stays an explicit override
- OCI DevOps runtime apply must be able to reconcile pre-DevOps runtime environments whose live load balancer resources exist in OCI but are missing from the remote Terraform state
- OCI DevOps runtime apply must be able to resume from a partially failed ingress-state migration, re-importing or recreating any missing listener, rule-set, or certificate resources rather than assuming the presence of the load balancer shell in state means ingress management is complete
- Runtime Terraform must not force destructive load balancer replacement solely because an imported OCI Load Balancer reports the attached reserved public IP through read-only IP address details instead of the original create-time input shape

## Acceptance Criteria

- [x] Deployment documentation exists for OCIR push + OCI Container Instance run.
- [x] Deployment docs include networking and ingress requirements.
- [x] Deployment docs include update strategy for new image versions.
- [x] Deployment docs include optional load balancer/TLS step.
- [x] Deployment docs include a concrete Let’s Encrypt manual issuance and manual 90-day renewal runbook.
- [x] Runtime Terraform manages OCI LB certificate, HTTPS listener and HTTP to HTTPS redirect.
- [x] Runtime docs define the OCI-managed TLS secret inputs consumed by Terraform.
- [x] Runtime Terraform assumes TLS is mandatory and always configures HTTPS + HTTP to HTTPS redirect.
- [x] Foundation networking allows public ingress to both HTTP (`80`) and HTTPS (`443`) listener ports on the Load Balancer.
- [x] Infrastructure is defined as code (IaC) for core OCI deployment resources.
- [x] Infrastructure is split into foundation/runtime stacks.
- [x] Runtime stack consumes foundation outputs and deploys by immutable image tag.
- [x] Repository includes deployment automation for publishing a runtime image and applying the runtime stack.
- [x] Deployment script supports safe image cleanup policy (retention-based) instead of deleting all previous images.
- [x] Deployment script cleanup does not fail a successful runtime deployment if repository lookup is unavailable.
- [x] Runtime supports private OCIR image pulls via explicit registry credentials.
- [x] Runtime outputs include direct HTTP access details (public IP and URL) after deploy.
- [x] Deployment exposes a stable public endpoint through OCI Load Balancer with reserved public IP.
- [x] Runtime deploy strategy minimizes 502 windows by keeping old backend alive until replacement backend is registered.
- [x] Load balancer health checks use HTTP readiness instead of raw TCP to reduce premature traffic routing.
- [x] Runtime exposes a dedicated management port for Spring Actuator health checks without adding a new public listener.
- [x] Load balancer health checks use Spring Actuator readiness instead of a learner-facing route.
- [x] Runtime container instances use private IPs only and do not receive public IP assignment.
- [x] Public ingress terminates at the OCI Load Balancer while the runtime backend stays on private VCN addressing.
- [x] Runtime retains private access to required OCI regional services after container public IP removal.
- [ ] OCI DevOps release automation executes `./mvnw clean verify`, then publishes a commit-traceable runtime image tag before runtime apply; on the current managed OCI runner this publication path is temporarily limited to `linux/amd64` until a native `arm64` or cross-build-capable release builder is available.
- [ ] The recommended repeatable release entrypoint is `infrastructure/oci/devops/run-release.sh` rather than a laptop-local wrapper.
- [ ] OCI DevOps release automation provisions or selects a Java 25 toolchain before running Maven verification and packaging steps.
- [ ] OCI DevOps private deployment shell execution provisions the PostgreSQL client needed by the repository bootstrap path before invoking `bootstrap-runtime-db-role.sh`.
- [ ] `./mvnw clean verify` and OCI DevOps release automation can build the verification image from Oracle no-fee Oracle-based images without requiring a separate Oracle base-image registry login.
- [x] OCI DevOps private deployment can configure the HTTPS listener without project-local PEM files by reading TLS material from OCI-managed secrets.
- [x] Runtime stage resolves `image_tag` automatically (existing deployed tag) when not explicitly provided, and only fails when no prior runtime tag exists.
- [ ] OCI DevOps runner IAM includes the runtime load balancer permissions needed for normal production rollout without broadening unrelated tenancy access.
- [ ] OCI DevOps runtime apply can import the existing public load balancer resources into remote state when migrating a pre-DevOps environment instead of trying to create a second live ingress stack.
- [x] Scope explicitly excludes database and Kubernetes/OKE.

## Non-goals

- Kubernetes (OKE) deployment.
- Database provisioning and migration.
