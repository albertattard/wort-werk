---
id: TASK-054
title: Design OCI OKE Blue-Green Runtime
status: in_progress
category: infrastructure
related_features:
  - SPEC-009
owner: @aattard
created: 2026-04-21
updated: 2026-04-22
---

## Summary

Define the managed Kubernetes replacement for the current OCI Container Instance runtime, including one-namespace blue-green slot structure, `Service`-based traffic switching, Kubernetes manifests, OCI DevOps pipeline contracts, and the required private-network shape for OKE worker nodes.

## Scope

- Document why OKE replaces the single-container runtime for the managed production target.
- Define the blue and green deployment slots inside one production namespace and how OCI DevOps selects the inactive slot.
- Define the stable production `Service` and traffic-switch mechanism.
- Define the required OKE networking boundary, including dedicated private endpoint and worker subnets with NAT plus service-gateway routing, explicit OKE security rules, and a bastion-backed operator access path.
- Provide repository-tracked Kubernetes manifests for the Java application `Deployment`, `Service`, and optional ingress exposure.
- Provide OCI DevOps build and deploy specifications for image build, push, rollout, health gating, and old-slot decommissioning.
- Keep the design aligned with the existing OCI DevOps-first release direction rather than introducing a second manual deployment control plane.

## Constraints

- The rollout must keep the public endpoint stable across slot changes.
- Traffic switching must happen only after readiness and rollout checks succeed.
- The stable Kubernetes `Service` must remain the switch point between the old and new versions.
- Automatic old-slot teardown is required, but the resulting rollback tradeoff must be documented explicitly.
- OCI DevOps remains the only normal production release path.
- The Kubernetes API endpoint must not reuse the existing DevOps subnet.
- OKE worker nodes must not be placed into the existing application runtime subnet.
- Private-cluster operator access must not assume laptop reachability to private VCN addresses.

## Out of Scope

- Implementing the full OKE Terraform stack in this task.
- Migrating live production traffic in this task.
- Adding service-mesh or canary-routing behavior.

## Acceptance Criteria

- [ ] `SPEC-009` documents the OKE runtime direction and links to this task.
- [ ] An ADR records the move from Container Instances to OKE for managed blue-green rollout.
- [ ] Repository docs define dedicated OKE endpoint and worker subnets and explain why the existing DevOps and runtime subnets are not valid shortcuts for OKE.
- [ ] Repository docs and scripts define a bastion-backed administration flow for private-cluster bootstrap and troubleshooting.
- [ ] Repository-tracked manifests exist for the Java runtime workload on Kubernetes.
- [ ] Repository-tracked OCI DevOps build and deploy specs exist for OKE rollout.
- [ ] Documentation explains the rollout sequence, health gates, and cleanup behavior clearly enough to implement the infrastructure next.

## Notes

- The stable production `Service` is the recommended blue-green switch point.
- ingress-nginx remains documented as an optional exposure layer, not the primary slot-switch primitive.
- The initial shortcut of reusing the existing runtime subnet for OKE workers proved invalid after real node registration timeouts and is no longer an acceptable design option.
- Reusing the existing DevOps subnet for the private Kubernetes API endpoint is also no longer an acceptable design option; the endpoint needs its own documented network boundary and rules.
- Running `kubectl` directly from a laptop against the private cluster endpoint is also no longer an acceptable operational assumption; the repository needs an explicit bastion-backed admin flow.
