---
id: TASK-047
title: Place OCI Runtime in Private Subnet
status: done
category: infrastructure
related_features:
  - SPEC-003
  - SPEC-008
owner: @aattard
created: 2026-04-12
updated: 2026-04-12
---

## Summary

Remove direct public-IP exposure from the OCI application runtime by moving the container instance behind private VCN addressing while preserving the Load Balancer public entrypoint and private access to required OCI services.

## Scope

- Add a dedicated private runtime subnet for the application container instance.
- Keep the OCI Load Balancer on a public subnet with the reserved public IP.
- Remove public IP assignment from the runtime container instance VNIC.
- Add private OCI service access needed for runtime dependencies such as Vault-backed secret retrieval.
- Update deploy/destroy wiring, docs, and outputs to reflect the new subnet split and runtime networking model.
- Correct older documentation that still assumes a container-instance public IP.

## Assumptions

- The OCI Load Balancer can route to a private backend IP within the same VCN.
- Runtime startup depends on OCI Vault, so removing the container public IP must not strand secret retrieval.
- General outbound internet access is not a deployment requirement unless the runtime later gains a concrete dependency that cannot use OCI private service access.

## Acceptance Criteria

- [x] Foundation Terraform provisions separate public and private subnets for load balancer and runtime responsibilities.
- [x] Runtime Terraform deploys the container instance without public IP assignment.
- [x] Public ingress remains available through the reserved Load Balancer public IP.
- [x] Runtime private networking preserves access to required OCI regional services.
- [x] OCI docs describe the new runtime-private networking model and operator implications.
- [x] `./mvnw clean verify` passes after changes.
