---
id: SPEC-008
title: OCI PostgreSQL and Secure Runtime Connectivity
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-12
---

## Problem

Wort-Werk now depends on PostgreSQL for authentication, but the OCI infrastructure currently mixes bootstrap resources and PostgreSQL provisioning in the same Terraform stack. That forces a toggle-based, two-pass apply flow and makes the database lifecycle less clear than it should be.

## Goal

Provision PostgreSQL-capable OCI infrastructure and wire the runtime container to it using concrete security controls rather than ad hoc credentials or permissive networking, while separating durable bootstrap infrastructure, stateful data infrastructure, and application runtime into explicit layers.

## Security Requirements

The infrastructure must satisfy all of the following:

1. The database must not have a public endpoint.
2. Application-to-database traffic must stay on private OCI networking.
3. Network rules must allow database ingress only from the application tier, not from the public internet.
4. Database credentials must not be stored in the repository, generated Terraform files committed to git, or hard-coded in container images.
5. Runtime secrets must be sourced from OCI-managed secret storage or an equivalent off-repo secret source.
6. Application-to-database traffic must use TLS in transit.
7. The database service must have automated backups and basic production-safe operational defaults enabled.
8. The runtime contract must make the application’s database settings explicit:
   - `WORTWERK_DB_URL`
   - `WORTWERK_DB_USERNAME`
   - `WORTWERK_DB_PASSWORD`
9. Runtime container instances must not receive public IP addresses; internet-facing traffic must terminate at the OCI Load Balancer instead of the application container.
10. Runtime access to OCI-managed dependencies required at startup, such as Vault secret retrieval, must remain available through private OCI networking rather than public internet exposure.

## Deployment Model

Use a three-stack OCI split:

- `foundation`
  - provisions shared environment resources required before secrets or database creation
  - owns compartment, shared network, Vault, KMS key, OCIR repository, reserved public IP, and baseline IAM/dynamic-group scaffolding
- `data`
  - provisions PostgreSQL-specific resources and secret-dependent IAM/policy wiring
  - consumes shared foundation outputs and Vault secret OCIDs
- `runtime`
  - provisions the application runtime and consumes database connection outputs and secret references from `data`

The apply order must be:
1. `foundation`
2. create or rotate required Vault secrets outside Terraform
3. `data`
4. `runtime` or `release`

## Scope

- Add OCI-managed PostgreSQL infrastructure.
- Add private subnet and network security rules for database access.
- Decide and document how DB credentials are stored and injected into runtime.
- Prevent operator workflows from configuring a runtime DB secret that cannot authenticate the currently configured runtime DB user.
- Split OCI Terraform into `foundation`, `data`, and `runtime` responsibilities.
- Keep Terraform naming consistent by using locals for fixed Wort-Werk resource identity and variables only for deployment-specific inputs.
- Wire runtime Terraform/container configuration to the managed PostgreSQL endpoint.
- Remove direct public-IP exposure from runtime container instances while preserving access to OCI regional services needed at startup.
- Document the operational steps needed for first deployment and future rotation of DB credentials.

## Out of Scope

- Per-user learning progress features.
- Multi-instance app scaling.
- Database schema redesign beyond what existing migrations already require.
- Full disaster-recovery topology or multi-region failover.

## Acceptance Criteria

- [ ] Repository docs define a managed PostgreSQL deployment path in OCI using `foundation`, `data`, and `runtime` stacks.
- [ ] Foundation Terraform scope excludes secret-dependent PostgreSQL provisioning.
- [ ] Data Terraform scope owns managed PostgreSQL provisioning and DB-secret-dependent policy wiring.
- [ ] Runtime Terraform consumes DB connectivity inputs from `data` without storing DB secrets in version control.
- [ ] OCI Terraform naming is consistent across stacks, with fixed resource names centralized in locals.
- [ ] Security requirements for private networking, TLS in transit, and least-privilege ingress are documented.
- [ ] Secret-handling approach for app-to-DB credentials is explicitly documented.
- [ ] Secret bootstrap workflow prevents mismatched runtime credentials for the configured runtime DB user.
- [ ] Implementation task(s) are linked from this spec before infrastructure changes begin.
