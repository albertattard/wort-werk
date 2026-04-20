---
id: TASK-045
title: Split OCI PostgreSQL into Dedicated Data Stack
status: in_progress
category: infrastructure
related_features:
  - SPEC-008
owner: @aattard
created: 2026-04-10
updated: 2026-04-20
---

## Summary

Restructure Wort-Werk OCI infrastructure so shared bootstrap resources, PostgreSQL data resources, and application runtime are provisioned in separate Terraform stacks.

## Scope

- Remove PostgreSQL provisioning from `foundation`.
- Introduce a dedicated `data` Terraform stack for managed PostgreSQL and secret-dependent policy wiring.
- Keep `runtime` consuming DB connection and secret outputs without storing DB secrets in git.
- Make the secret bootstrap workflow safe while `runtime_db_username` still defaults to the PostgreSQL admin user.
- Keep bootstrap control-plane prerequisites, such as the OCI compartment and Terraform state bucket, documented outside `foundation` when they must exist before Terraform backend or stack initialization.
- Standardize OCI Terraform naming so fixed Wort-Werk resource names live in locals while deployment-specific values remain variables.
- Standardize shared freeform tagging in `foundation` so supported OCI resources inherit a single centralized `group_id` tag value.
- Keep database-tier network resource names aligned with the tier they serve so `foundation` naming stays parallel with `runtime` and `devops`.
- Keep runtime-tier network security group names aligned with the runtime tier itself so NSG naming stays parallel with load balancer, database, and DevOps tiers.
- Keep network security group rule names aligned with the tiers they connect so the traffic flow stays readable across load balancer, runtime, database, and DevOps.
- Use full tier names in network security group rule identifiers and add `for_<qualifier>` only when a trailing qualifier is needed to distinguish sibling rules.
- Keep fixed infrastructure port values, such as the PostgreSQL service port, centralized in locals when they are part of the stable network contract rather than deployment inputs.
- Update deploy and destroy orchestration to use `foundation -> data -> runtime` ordering.
- Update OCI runbooks and infrastructure docs to reflect the new stack split and bootstrap sequence.

## Security Constraints

- No public database endpoint.
- No repository-stored production DB credentials.
- No broad `0.0.0.0/0` ingress to the database tier.
- TLS in transit must be part of the runtime design.
- Database access must be limited to the application tier.
- Runtime secret read access must stay scoped to the specific runtime DB password secret.
- Secret bootstrap must not make it easy to deploy a runtime password that cannot authenticate the configured runtime DB user.

## Out of Scope

- Implementing progress tracking features.
- Multi-region HA/failover.
- Replacing PostgreSQL with another database.
- Introducing a least-privilege non-admin application DB role in this task.

## Acceptance Criteria

- [ ] `infrastructure/oci/data/` exists and validates as a standalone Terraform stack.
- [ ] `foundation` no longer requires `postgresql_enabled` or DB secret OCIDs.
- [ ] `data` owns OCI PostgreSQL, connection outputs, and runtime secret-read policy resources.
- [ ] Fixed OCI resource names are centralized consistently across `foundation`, `data`, and `runtime`.
- [ ] `deploy.sh` and `destroy.sh` support the `foundation -> data -> runtime` lifecycle correctly.
- [ ] OCI docs describe first-time setup, secret creation, and apply order without a two-pass foundation toggle.
- [ ] Existing runtime DB contract remains intact for the application.
- [ ] Secret bootstrap workflow either reuses the admin password for runtime by default or blocks incompatible values while runtime uses the admin DB user.
- [ ] `docs/spec/README.md` and `docs/tasks/README.md` continue to reference the updated spec and task.
