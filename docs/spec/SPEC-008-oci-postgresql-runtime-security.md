---
id: SPEC-008
title: OCI PostgreSQL and Secure Runtime Connectivity
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-10
---

## Problem

Wort-Werk now depends on PostgreSQL for authentication, but the OCI infrastructure only provisions container runtime resources. Production deployment is incomplete until OCI includes a database and secure application-to-database connectivity.

## Goal

Provision PostgreSQL-capable OCI infrastructure and wire the runtime container to it using concrete security controls rather than ad hoc credentials or permissive networking.

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

## Deployment Model

Keep the existing two-stack OCI split:

- `foundation`
  - provisions shared environment resources, now including database network prerequisites and the managed PostgreSQL service
- `runtime`
  - provisions the application runtime and consumes database connection outputs and secret references from foundation

## Scope

- Add OCI-managed PostgreSQL infrastructure.
- Add private subnet and network security rules for database access.
- Decide and document how DB credentials are stored and injected into runtime.
- Wire runtime Terraform/container configuration to the managed PostgreSQL endpoint.
- Document the operational steps needed for first deployment and future rotation of DB credentials.

## Out of Scope

- Per-user learning progress features.
- Multi-instance app scaling.
- Database schema redesign beyond what existing migrations already require.
- Full disaster-recovery topology or multi-region failover.

## Acceptance Criteria

- [ ] Repository docs define a managed PostgreSQL deployment path in OCI.
- [ ] Foundation Terraform scope includes managed PostgreSQL and private database networking.
- [ ] Runtime Terraform consumes DB connectivity inputs without storing DB secrets in version control.
- [ ] Security requirements for private networking, TLS in transit, and least-privilege ingress are documented.
- [ ] Secret-handling approach for app-to-DB credentials is explicitly documented.
- [ ] Implementation task(s) are linked from this spec before infrastructure changes begin.
