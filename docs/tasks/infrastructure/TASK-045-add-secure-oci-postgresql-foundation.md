---
id: TASK-045
title: Add Secure OCI PostgreSQL Foundation
status: pending
category: infrastructure
related_features:
  - SPEC-008
owner: @aattard
created: 2026-04-10
updated: 2026-04-10
---

## Summary

Extend Wort-Werk OCI infrastructure so the deployed application can connect to a managed PostgreSQL database through private networking and explicit secret handling.

## Scope

- Select the OCI-managed PostgreSQL deployment approach for Wort-Werk.
- Extend foundation Terraform with database-related infrastructure and secure network boundaries.
- Define how runtime receives `WORTWERK_DB_URL`, `WORTWERK_DB_USERNAME`, and `WORTWERK_DB_PASSWORD`.
- Document the secret source and rotation approach.
- Update deployment runbooks and infrastructure docs to cover first-time DB-enabled rollout.

## Security Constraints

- No public database endpoint.
- No repository-stored production DB credentials.
- No broad `0.0.0.0/0` ingress to the database tier.
- TLS in transit must be part of the runtime design.
- Database access must be limited to the application tier.

## Out of Scope

- Implementing progress tracking features.
- Multi-region HA/failover.
- Replacing PostgreSQL with another database.

## Acceptance Criteria

- [ ] OCI database approach is documented and justified in repo docs.
- [ ] Required OCI resources and security boundaries are documented before Terraform changes.
- [ ] Runtime secret injection approach is documented.
- [ ] Follow-up implementation steps are concrete enough to build the Terraform changes without ambiguity.
- [ ] `docs/spec/README.md` and `docs/tasks/README.md` reference the new spec and task.
