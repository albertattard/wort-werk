---
id: SPEC-008
title: OCI PostgreSQL and Secure Runtime Connectivity
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-19
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
11. The runtime database user must be distinct from the PostgreSQL administrator account and limited to application-owned database/schema responsibilities rather than broader instance administration.
12. When TLS terminates at the OCI Load Balancer, the application must trust forwarded host/protocol headers so login redirects and WebAuthn-adjacent browser flows remain on the public HTTPS origin instead of bouncing through `http://`.

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
4. bootstrap or rotate the dedicated runtime DB role from a host with private DB connectivity
5. `runtime` or `release`

## Scope

- Add OCI-managed PostgreSQL infrastructure.
- Add private subnet and network security rules for database access.
- Decide and document how DB credentials are stored and injected into runtime.
- Decide and document how release and deployment execution move inside OCI instead of relying on an operator laptop for private-network steps.
- Prevent operator workflows from configuring a runtime DB secret that cannot authenticate the currently configured runtime DB user.
- Introduce a dedicated non-admin runtime DB role and document its privilege boundary.
- Split OCI Terraform into `foundation`, `data`, and `runtime` responsibilities.
- Keep Terraform naming consistent by using locals for fixed Wort-Werk resource identity and variables only for deployment-specific inputs.
- Name stable network resources after the tier they serve when possible, rather than using generic labels such as `private` that apply to multiple tiers.
- Name security-group resources after the network tier they protect, rather than after the application name, so tier boundaries stay readable across runtime, load balancer, database, and DevOps.
- Name security-group rules after the network tiers they connect, rather than implementation details such as containers, so traffic boundaries stay readable.
- Use full tier names in security-group rule identifiers and reserve `for_<qualifier>` for the trailing traffic qualifier only when it distinguishes sibling rules.
- Keep fixed infrastructure protocol ports in locals when they are part of the stable OCI network contract, rather than surfacing them as operator-tunable variables.
- Wire runtime Terraform/container configuration to the managed PostgreSQL endpoint.
- Remove direct public-IP exposure from runtime container instances while preserving access to OCI regional services needed at startup.
- Document the operational steps needed for first deployment and future rotation of DB credentials.
- Keep operator-facing helper examples aligned with the actual script defaults so documentation does not imply redundant environment variables are mandatory.

## Release Execution Model

Secure release and deployment execution must satisfy all of the following:

1. The build and deployment control path must run from OCI-managed infrastructure rather than an operator laptop when private-network access is required.
2. A release must target an explicit git reference, with the exact commit recorded in the produced image tag or deployment metadata.
3. Verified release images must be built and published by the OCI-managed release pipeline rather than by a laptop-local `docker buildx` flow.
3. The runner that performs private-network deployment steps should be ephemeral or OCI-managed rather than a long-lived manually administered VM unless an ADR explicitly accepts that tradeoff.
4. The runner must execute inside OCI networking that can reach the private PostgreSQL endpoint without exposing the database publicly.
5. Release automation must keep administrator credentials, runtime credentials, and image registry credentials out of repository-tracked files.
6. Database role bootstrap and runtime rollout must be part of the reproducible release path rather than an undocumented side step.
7. OCI DevOps runner identities must use explicit dynamic-group and policy bindings instead of inheriting broad tenancy-wide privileges.
8. Secret-read permissions for external SCM connections and OCI-resident deploy/bootstrap steps must be scoped to the specific secret OCIDs used by the release path.
9. Private DevOps runners must have an explicit egress design for external SCM access; if public internet egress is required, it must be isolated to the DevOps subnet through a controlled outbound path such as NAT and must not be reused by the runtime subnet.
10. Release bundle handoff between OCI DevOps stages must use a deterministic OCI-managed storage boundary with explicit object naming and IAM scope instead of relying on opaque managed artifact delivery that cannot be diagnosed or reproduced from repository state.
11. The release handoff must preserve commit-to-artifact traceability by addressing release bundle and metadata objects with the selected release version.
12. The deployment stage must not depend on laptop-local Terraform state or laptop-local foundation/data outputs; all required deployment inputs must be available to the OCI runner through remote state or OCI-managed release metadata.
13. The runtime Terraform state used by OCI-resident deployment must live in a remote OCI-managed backend, with an explicit guard against applying from an empty or missing remote state object.
14. Release trigger inputs must remain small and explicit; stable runtime configuration belongs on OCI-managed pipeline defaults, and large PostgreSQL connection material such as CA certificates must be resolved inside OCI from authoritative service APIs rather than being copied through ad hoc build arguments.
15. OCI-resident rollout helpers must resolve OCI Object Storage namespace information from OCI APIs or OCI-provided release inputs, not from laptop-oriented Terraform output fallbacks that may be absent in the managed runner workspace.
16. OCI DevOps runner IAM must include read access to OCI PostgreSQL database-system connection details when the build resolves runtime TLS material from the OCI PostgreSQL API.
17. The private OCI DevOps deploy runner must have least-privilege read access to the specific Vault secrets used for runtime image pulls and PostgreSQL bootstrap, including the runtime DB password and PostgreSQL administrator password secrets, without broad secret-family access.
18. Repository-owned PostgreSQL bootstrap scripts executed from OCI-managed deploy runners must remain compatible with the PostgreSQL client version provisioned on those runners and must not depend on unsupported `psql` meta-commands.
19. OCI-resident Terraform apply must configure the OCI provider auth mode explicitly for managed-runner execution; Terraform must not assume OCI CLI authentication environment variables automatically configure provider authentication.
20. OCI-resident runtime apply must obtain TLS certificate inputs from OCI-managed secret sources rather than repository-local files so the deploy runner can reproduce HTTPS configuration without laptop-local workspace material.
21. OCI DevOps runner IAM must include the least-privilege OCI permissions required to manage the runtime load balancer and attach its reserved public IP during OCI-resident rollout.
22. OCI-resident runtime rollout must detect and repair pre-DevOps Terraform state drift when existing load balancer resources are live in OCI but absent from the remote runtime state.
23. OCI-resident runtime rollout must be resumable after a partial failed state-repair attempt; if some imported load balancer child resources are missing from remote state, the next rollout must repair those gaps before apply rather than proceeding with a half-managed ingress stack.
24. Runtime Terraform must preserve the reserved public IP on initial load balancer creation without forcing destructive replacement of an imported live load balancer on every subsequent OCI-resident rollout.
25. OCI-resident runtime state repair must verify that a missing ingress child resource still exists in OCI before importing it; if the failed rollout already deleted it, repair must skip the import and allow Terraform to recreate the resource normally.

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
- [x] Secret bootstrap workflow prevents mismatched runtime credentials for the configured runtime DB user.
- [x] Runtime DB connectivity no longer defaults to the PostgreSQL administrator account.
- [x] Repository docs define the least-privilege boundary for the runtime DB role and the bootstrap path that provisions it.
- [ ] Repository docs define an OCI-resident release runner or pipeline that can execute private-network deployment steps reproducibly.
- [ ] Release execution is documented to target an explicit git reference and preserve commit-to-image traceability.
- [ ] Repository docs define OCI DevOps as the only supported release-image build/publish path for normal production rollout.
- [ ] Repository docs define how private-network DB bootstrap is executed from OCI-managed infrastructure instead of an operator laptop.
- [ ] Repository docs define the DevOps runner IAM model, including dynamic groups and least-privilege policies for private-network execution, external-connection secret reads, and the specific Vault secrets required by OCI-resident DB bootstrap and runtime rollout.
- [ ] Repository docs define the DevOps runner outbound network model, including how private build stages reach external SCM without broadening runtime subnet exposure.
- [ ] Repository docs define the OCI-native release artifact handoff boundary, including why the chosen storage path is preferred over OCI DevOps managed deliver-artifact stages.
- [ ] Repository docs define how OCI-resident deploy stages obtain runtime inputs without reading laptop-local `foundation` or `data` Terraform state files.
- [ ] Repository docs define the remote runtime Terraform backend used by OCI deployment and the migration guardrails around it.
- [x] Repository docs define how OCI DevOps rollout obtains HTTPS certificate material without project-local PEM files.
- [x] Application runtime configuration preserves public HTTPS origin semantics behind OCI load balancer TLS termination.
- [ ] Repository docs define the least-privilege load balancer/public-IP permissions required by the OCI DevOps runner for runtime apply.
- [ ] Repository docs define how OCI DevOps repairs pre-DevOps runtime load balancer state drift before the normal rollout path is used.
- [x] Top-level OCI operator documentation reflects the OCI DevOps-first release path, the guarded runtime migration/apply behavior, and the current helper-script input/output contracts without stale laptop-era guidance.
- [ ] Implementation task(s) are linked from this spec before infrastructure changes begin.
