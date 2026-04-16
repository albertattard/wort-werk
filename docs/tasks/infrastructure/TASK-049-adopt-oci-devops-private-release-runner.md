---
id: TASK-049
title: Adopt OCI DevOps Private Release Runner
status: in_progress
category: infrastructure
related_features:
  - SPEC-008
owner: @aattard
created: 2026-04-12
updated: 2026-04-16
---

## Summary

Replace laptop-driven OCI release and private database bootstrap steps with an OCI-resident, reproducible release path that builds the verified runtime image from an explicit git reference and runs private-network deployment steps inside OCI.

## Scope

- Define the OCI-native release execution path for Wort-Werk.
- Prefer OCI DevOps managed build and deployment pipelines over a long-lived manually administered deployment VM.
- Ensure the release path can target an explicit branch and commit.
- Ensure build outputs preserve commit-to-image traceability.
- Move verified image publication to OCI DevOps so normal releases no longer depend on laptop-local `docker buildx` or `deploy.sh release`.
- Ensure the release path can execute private-network steps such as runtime DB role bootstrap and runtime rollout from inside OCI.
- Define the trust boundaries, IAM scope, secret delivery model, and network placement for the release runner.
- Replace OCI DevOps managed `DELIVER_ARTIFACT` handoff stages with an explicit OCI-native storage handoff that the build and deploy stages can both observe and diagnose.
- Provide OCI-resident deployment with the runtime inputs it needs without reading laptop-local `foundation` or `data` Terraform state files.
- Move runtime Terraform state to a remote OCI-managed backend so the deploy stage can apply an existing tracked runtime state instead of reconstructing from an empty workspace.
- Document the operator workflow for manually triggered releases.

## Security Constraints

- Private PostgreSQL access must continue to stay inside OCI private networking.
- The release runner must not require repository-tracked static cloud credentials.
- Long-lived standing privileges should be minimized; ephemeral or OCI-managed execution is preferred over a permanent general-purpose VM.
- The release path must not make the PostgreSQL endpoint public just to simplify deployment.
- The release path must not deploy ambiguous workspace state; it must target an explicit git reference.
- Private build and deployment stages may use constrained outbound internet egress only where required to fetch source or dependencies, and that egress must not be shared with the runtime subnet.
- Release artifact storage must be writable by the build path and readable by the deploy path through tightly scoped OCI IAM permissions rather than broad tenancy access.
- Runtime state storage must be writable and readable by the deploy path through tightly scoped OCI IAM permissions and must not silently fall back to a new empty local state.

## Architecture Notes

- OCI DevOps provides a stronger default foundation than a hand-maintained build VM because it separates build orchestration, deployment orchestration, and OCI-managed identity concerns.
- A shell-based deployment stage running inside a private subnet is the intended place for private-network steps such as DB role bootstrap.
- A dedicated runner image with pinned tooling versions may still be needed, but that image should be an implementation detail of the managed pipeline rather than an always-on control-plane VM.
- The release runner requires an explicit OCI IAM layer: a dedicated DevOps dynamic group plus policies for `devops-family`, private-network attachments, constrained Object Storage release handoff, and external-connection secret reads.
- The release handoff should prefer a simple OCI primitive that can be inspected independently of OCI DevOps stage internals; commit-addressed Object Storage objects are a better fit than opaque managed deliver-artifact stages.
- OCI-resident deploy stages should consume explicit release metadata produced by the build stage rather than reaching back into a laptop-local workspace for `foundation` or `data` outputs.
- OCI DevOps build-run arguments should carry only per-run selectors; stable runtime inputs belong on the pipeline definition, and oversized runtime material such as PostgreSQL CA certificates must be resolved inside OCI instead of being inlined into build-run arguments.
- The legacy laptop `release` / `rollout` helpers should not remain a second normal release path once OCI DevOps owns verified image publication and private rollout.

## Out of Scope

- Full CI automation on every push.
- Multi-environment promotion workflows beyond the current production-oriented OCI rollout.
- Replacing Terraform with another infrastructure tool.

## Acceptance Criteria

- [ ] Repository docs define the chosen OCI-native release architecture and explain why it is preferred over a long-lived deployment VM.
- [ ] The release path is documented to accept an explicit git reference and preserve commit-to-image traceability.
- [ ] OCI DevOps builds and publishes the verified runtime image; laptop-local `deploy.sh release` is no longer the normal release path.
- [ ] The release path is documented to execute DB role bootstrap and runtime rollout from inside OCI private networking.
- [ ] IAM, secret, and network boundaries for the release runner are explicit.
- [ ] The private OCI DevOps deploy runner receives least-privilege read access to the specific Vault secrets required for OCI-resident DB bootstrap and runtime rollout rather than broad secret-family access.
- [ ] The network design explains how private DevOps runners fetch source from external SCM without widening runtime subnet exposure.
- [ ] The release handoff boundary is documented, including why Object Storage is used instead of OCI DevOps managed deliver-artifact stages.
- [ ] OCI deploy stages receive the runtime inputs they need through OCI-managed release metadata or equivalent OCI-resident inputs rather than laptop-local Terraform state.
- [ ] Runtime Terraform uses a remote OCI backend that the OCI deploy stage can access safely.
- [ ] The private OCI DevOps shell stage provisions the PostgreSQL client tooling required by the repository bootstrap script instead of assuming `psql` is preinstalled on the managed shell image.
- [ ] Legacy laptop release helpers are removed or blocked for standard production releases.
- [ ] Follow-on implementation steps are broken down before infrastructure changes begin.

## Implementation Notes

- The current Terraform now provisions the DevOps project, private subnet placement, and project logging.
- A live build-run exposed the next missing slice: the private DevOps subnet can reach OCI services and PostgreSQL, but cannot fetch source from GitHub without a dedicated egress path.
- The repository-side source checkout and release packaging path now succeeds on OCI DevOps private runners.
- Repeated build runs then failed in both OCI DevOps `DELIVER_ARTIFACT` stages with the same OCI-managed internal error, even after the packaged release bundle was saved successfully.
- The next implementation step is to extend that release handoff with:
  - build-stage verification and OCI-managed image publication to OCIR
  - build-stage upload of commit-addressed metadata that includes the OCI-resident deployment inputs
  - deploy-stage download of those same objects from the private shell stage
  - a remote runtime Terraform backend accessible from the OCI deploy runner
  - removal or blocking of the legacy laptop-local release wrappers
- OCI DevOps pipeline parameter defaults now carry the stable runtime deployment contract, while `run-release.sh` only passes `releaseVersion` and `tfBackendMode`.
- PostgreSQL CA material is now resolved inside OCI from the DB system connection-details API so the build pipeline no longer exceeds OCI DevOps parameter size limits.
- The DevOps dynamic-group policy must include `read postgres-db-systems` so the build runner can call `GetConnectionDetails` against the managed PostgreSQL system.
- A live deployment reached the private DB bootstrap step from the managed shell stage and failed because `psql` was not present on the OCI-managed shell image. The deploy command spec must therefore provision the PostgreSQL client as part of the shell-stage contract rather than assuming the base image already carries it.
- The next live deployment then proved the shell stage also needs explicit read access to the PostgreSQL administrator and runtime DB password secrets. The DevOps runner policy must stay least-privilege by scoping secret access to those specific OCIDs instead of granting broad Vault reads.
- The next live deployment then proved the Oracle Linux 8 PostgreSQL client available on the managed shell does not support `\getenv`. The repository bootstrap script must therefore pass the runtime DB password through stable `psql --set` arguments rather than relying on newer client-only meta-commands.
- The next live deployment then proved `psql` variable substitution does not occur inside the dollar-quoted `DO` body used by the bootstrap script. The role-create/alter step must stay in top-level SQL plus `\gexec`, where `psql` variable expansion is actually supported on the managed client.
- The bootstrap script should not leave the runtime DB password on the `psql` process command line. Even after moving away from `\getenv`, the password must be injected through stdin-only `psql` input so it does not appear in runner process arguments.
- The next live deployment then proved OCI PostgreSQL rejects `ALTER ... OWNER TO wortwerk_app` when the administrator role cannot `SET ROLE wortwerk_app`. The bootstrap path must therefore grant the runtime role to the administrator only for the ownership-handoff window and revoke that membership again during cleanup so the steady-state privilege boundary remains intact.
- Current managed OCI runners can publish `linux/amd64`, but they fail `linux/arm64` image builds with `exec format error` during target-architecture `RUN` steps because no arm emulation or native `arm64` builder is available. The release contract is therefore temporarily constrained to `linux/amd64`.
- The latest live deployment then proved the OCI-resident runtime rollout must not derive the Object Storage namespace from laptop-oriented Terraform output fallback. Inside the managed deploy runner, runtime backend initialization must resolve the namespace from OCI itself, or from OCI-provided environment, so Terraform warnings from an empty local `foundation` state cannot corrupt the generated backend config.
