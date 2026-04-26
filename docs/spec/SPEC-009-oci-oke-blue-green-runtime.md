---
id: SPEC-009
title: OCI OKE Blue-Green Runtime
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-26
---

## Problem

The current OCI production path is built around a single Container Instance behind an OCI Load Balancer.
That path is simple, but it keeps deployment overlap, rollout isolation, and future horizontal scaling more fragile than they should be for a managed runtime target.

## Goal

Replace the single-container OCI runtime with an Oracle Kubernetes Engine (OKE) deployment model that supports managed blue-green rollouts, readiness-gated traffic switching, and OCI DevOps-driven release automation.

This spec supersedes `SPEC-003` as the recommended managed production runtime direction.

## Linked Task

- `TASK-054`: `docs/tasks/infrastructure/TASK-054-design-oci-oke-blue-green-runtime.md`
- `TASK-055`: `docs/tasks/infrastructure/TASK-055-add-github-push-triggered-oci-app-release.md`

## User-facing Behavior

- Wort-Werk is reachable through a stable public endpoint backed by OKE.
- A push to the repository trunk branch automatically starts the OCI application release pipeline when the push includes application/runtime changes.
- A new application version is deployed into an inactive blue or green slot without interrupting active traffic.
- Traffic switches to the new version only after Kubernetes readiness and release smoke checks pass.
- The previously active version stays available during post-switch observation and is decommissioned automatically only after the new version passes that observation window.
- If the new version returns qualifying HTTP errors during post-switch observation, traffic is switched back to the previously active version and the failed new slot is stopped.

## Architecture Direction

Use OKE as the application runtime tier with one stable production namespace and two fixed deployment slots inside it:

- namespace: `wortwerk-prod`
- slots: `blue` and `green`

Each slot owns:

- one Kubernetes `Deployment`
- slot-local configuration and secret references

Shared runtime resources remain stable while the active slot changes:

- one stable Kubernetes `Service` that represents the active production version
- optional public exposure through an OCI load balancer-backed `Service` or ingress-nginx

The recommended blue-green design uses the stable Kubernetes `Service` as the switch point.
That is intentional: the requirement is to keep the old Pods serving traffic until the new Pods are ready, then switch and remove the old version.
That behavior is simpler and less failure-prone when the switch happens by updating one `Service` selector instead of coordinating two namespaces and an external edge cutover.

## Deployment Model

OCI layers:

- `foundation`
  - VCN, public and private subnets, NSGs, OCIR, public ingress address, and OKE prerequisites
- `data`
  - PostgreSQL and secret-dependent data infrastructure
- `oke`
  - OKE cluster, node pools, and cluster-scoped prerequisites for the application namespace
- `devops`
  - OCI DevOps build and deployment pipelines for release execution inside OCI

Application rollout model:

1. A push to the repository trunk branch starts the OCI DevOps application release pipeline unless the push only changes documentation or infrastructure paths.
2. Documentation-only changes under `docs/**` and infrastructure-only changes under `infrastructure/**` must not trigger the application release pipeline.
3. OCI DevOps build pipeline checks out the pushed git revision.
4. The build pipeline creates one candidate runtime container image with a commit-traceable immutable tag.
5. The build pipeline runs the functional, database-backed, and e2e verification suite against that exact candidate image.
6. If verification passes, the pipeline publishes the verified candidate image to OCIR without rebuilding a different runtime image.
7. The deploy pipeline deploys the verified image by immutable tag or digest.
8. The deploy pipeline determines the active and inactive slots from the stable production `Service`.
9. The deploy pipeline applies the target slot `Deployment` in the production namespace.
10. Kubernetes readiness probes and rollout status must pass before traffic switching.
11. The deploy pipeline updates the stable production `Service` selector to point at the target slot.
12. A post-switch observation window confirms the public endpoint remains healthy while the previous slot remains available.
13. If post-switch observation passes, the previously active slot `Deployment` is deleted automatically.
14. If post-switch observation fails, the stable production `Service` selector is switched back to the previously active slot and the failed target slot is stopped.

## Release Trigger Scope

- The repository follows trunk-based development, so the automatic application release trigger is scoped to pushes on the trunk branch.
- The application release pipeline is skipped when every changed path in a push is under `docs/**` or `infrastructure/**`.
- Changes outside `docs/**` and `infrastructure/**` are treated as application/runtime-affecting unless the implementation task defines a narrower, tested ignore list.
- The release trigger must not deploy unreviewed infrastructure changes. Terraform/foundation/data/OKE/DevOps infrastructure changes remain manually triggered from the operator laptop.
- Path filtering is an optimization for release execution, not a substitute for source traceability. Every triggered pipeline run must still record the exact git revision and image tag or digest it deployed.

## Verified Image Contract

- The container image tested by functional and e2e verification must be the same image artifact deployed to OKE.
- The pipeline must not run tests against one image and then build a second, untested runtime image for deployment.
- The verified image must be identified by an immutable, commit-traceable tag and preferably by digest for the deployment handoff.
- The deployment stage must fail closed if the verified image reference is missing, mutable, or cannot be matched to the checked-out git revision.

## Post-switch Observation and Rollback

- The previously active slot must remain running while post-switch observation is in progress.
- The post-switch observation window must be configurable and must default to at least two minutes.
- Observation must include repeated HTTP checks against the stable public endpoint and any required health endpoint exposed for release validation.
- A qualifying HTTP error is any `5xx` response, failed connection, timeout, or invalid health response from a route expected to be healthy. Expected authentication redirects or `4xx` responses on protected routes do not count as rollout errors unless the checked route is defined to be public.
- If any qualifying HTTP error is observed during the window, the deploy pipeline must switch the stable production `Service` selector back to the previously active slot and stop the failed target slot.
- A successful rollout may decommission the previous slot only after the observation window completes without qualifying HTTP errors.

## Requirements

1. OKE worker nodes and the Kubernetes API endpoint used by OCI DevOps must remain on private OCI networking.
2. The Kubernetes API endpoint must use a dedicated private endpoint subnet rather than reusing the existing DevOps subnet.
3. OKE worker nodes must use a dedicated private worker subnet rather than reusing the existing application runtime subnet.
4. The OKE endpoint and worker subnet route tables must provide both Oracle Services Network access through the service gateway and default outbound internet egress through a NAT gateway.
5. The OKE endpoint and worker subnets must define explicit security rules for worker-to-control-plane communication, Oracle Services Network access, and path discovery instead of relying on implicit default VCN behavior.
6. Private-cluster administration from an operator laptop must use a dedicated bastion or admin access path rather than assuming direct laptop reachability into the VCN.
7. Public ingress must terminate at a stable OCI-managed load balancer or ingress controller front door.
8. The deployment contract must use Kubernetes `Deployment` and `Service` resources for the application workload.
9. The application `Deployment` must define readiness probes against `/actuator/health/readiness`.
10. The rollout must not switch public traffic before the target slot `Deployment` is healthy.
11. OCI DevOps must be the normal release path for build, image publication, and deployment.
12. Images must be published to OCIR with immutable, commit-traceable tags.
13. The deploy path must be able to determine the currently active and inactive slots from cluster state without relying on an operator laptop.
14. Successful rollout must decommission the previous slot automatically after post-switch observation passes.
15. The design must preserve a stable public hostname and certificate boundary across slot changes.
16. "Fully running" for traffic-switch purposes must mean at least:
   - the target `Deployment` reports successful rollout,
   - target Pods are Ready,
   - and the post-switch public smoke and observation checks succeed.
17. Automatic application releases must be triggerable from repository trunk pushes while skipping documentation-only and infrastructure-only pushes.
18. Infrastructure changes must remain outside the automatic application release path and continue to require manual operator-triggered execution from the laptop.

## Tradeoffs

- Automatic teardown of the old slot reduces cost and configuration drift, but it also removes instant rollback to the exact previous runtime state.
- Keeping the old slot alive during post-switch observation costs more during rollout, but it preserves fast rollback until the new version proves healthy under public traffic.
- One namespace with a stable `Service` keeps the switch logic simple, but it provides less isolation than separate namespaces.
- ingress-nginx remains useful for public ingress, but it is not the blue-green switch primitive in this design; the stable application `Service` is.

## Out of Scope

- Multi-region failover.
- Service mesh adoption.
- Per-commit ephemeral preview environments.
- Autoscaling policy tuning beyond the baseline replica count needed for safe rollout overlap.

## Acceptance Criteria

- [ ] Repository docs define the OKE runtime architecture and explain why it replaces the single Container Instance path.
- [ ] Repository docs define blue-green deployment on OKE with one stable namespace and two fixed deployment slots.
- [ ] Repository docs define the stable edge design and the traffic-switch mechanism.
- [ ] Repository docs define dedicated private OKE endpoint and worker subnets, including their required routing and security rules.
- [ ] Repository docs define a bastion-backed operator access path for private-cluster administration from outside the VCN.
- [ ] Kubernetes manifests exist for the application `Deployment`, `Service`, and optional ingress-nginx exposure pattern.
- [ ] The `Deployment` manifest includes readiness and liveness probes suitable for zero-downtime rollout.
- [ ] OCI DevOps build configuration exists for verification, image build, and push to OCIR.
- [ ] OCI DevOps deploy configuration exists for kubeconfig setup, inactive-slot deployment, readiness-gated `Service` selector switching, and old-slot decommissioning.
- [ ] OCI DevOps release triggering is scoped to trunk pushes and skips documentation-only and infrastructure-only pushes.
- [ ] OCI DevOps verifies and deploys the same immutable container image artifact.
- [ ] OCI DevOps keeps the previous slot running during post-switch observation and rolls back traffic on qualifying HTTP errors.
- [ ] A linked implementation task exists before any OKE infrastructure changes begin.
