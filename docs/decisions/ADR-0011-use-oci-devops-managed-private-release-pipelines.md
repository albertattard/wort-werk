# ADR-0011: Use OCI DevOps Managed Private Release Pipelines

## Status
Accepted

## Context

Wort-Werk now has private OCI networking for runtime and database access, plus a dedicated non-admin runtime database role that must be bootstrapped from inside the private network. That makes operator-laptop-driven release execution an awkward and brittle trust boundary.

One option is to introduce a permanent OCI VM that can pull the repository, build the application, push images, run Terraform, and execute private PostgreSQL bootstrap steps. That would improve reachability, but it would also centralize too much standing privilege in a long-lived machine that becomes the deployment control plane.

OCI DevOps already provides managed build and deployment pipelines. Build runs can be started against a selected branch and commit, and deployment shell stages can run on a managed container-instance host inside a selected subnet using the pipeline resource principal.

The managed OCI build runner environment is not a laptop clone. In practice it is compatible with daemonless container tooling for image build and execution, but it does not provide a reliable Docker daemon socket for a repository workflow that shells out to `docker compose up`.

## Decision

Adopt OCI DevOps managed pipelines as the default Wort-Werk release foundation instead of introducing a permanent manually administered deployment VM.

The intended structure is:

1. Use an OCI DevOps build pipeline to check out a specific git reference, run verification, and publish a commit-traceable multi-architecture image.
2. Use an OCI DevOps deployment pipeline to execute private-network rollout steps from inside OCI.
3. Run private PostgreSQL bootstrap steps from a deployment shell stage inside a private subnet rather than from an operator laptop.
4. Prefer ephemeral or OCI-managed execution over long-lived general-purpose deployment hosts.
5. Provide external SCM reachability for private DevOps runners through a dedicated outbound path for the DevOps subnet rather than by widening runtime subnet internet access.
6. Use explicit OCI-managed storage as the release handoff boundary between build and deploy stages when OCI DevOps managed deliver-artifact stages are not operationally reliable enough for the required release bundle transfer.
7. Keep OCI-resident deployment independent from laptop-local `foundation` or `data` state by passing required deployment inputs through OCI-managed release metadata and by using a remote runtime Terraform backend.
8. Treat OCI DevOps as the sole supported production release path; operator laptops must not publish or deploy production releases.
9. Keep the repository verification contract stable at `./mvnw clean verify`, but let repository-owned helper scripts choose the backend implementation that fits the current environment.
10. Use a Podman-native verification backend on OCI DevOps managed runners rather than assuming a Docker daemon-backed Compose runtime is available there.

## Consequences

Positive:
- Release execution becomes reproducible and tied to explicit repository state instead of a mutable local workspace.
- Private-network deployment steps no longer depend on a human reaching into the VCN from an ad hoc machine.
- OCI-managed identity can replace some static operator credential handling.
- Runtime and release tiers can keep different egress boundaries instead of collapsing into one broader private-subnet policy.
- A commit-addressed Object Storage handoff is simpler to inspect and reason about than opaque OCI DevOps artifact-delivery stage internals.
- The build pipeline can stay on OCI-managed runners without introducing a custom VM purely to recover a Docker-daemon assumption that the managed service does not make.

Negative:
- OCI DevOps resources, permissions, and pipeline definitions add new infrastructure surface area.
- Build and deployment concerns must be modeled explicitly instead of hidden in local shell scripts.
- Private runners that need external SCM access still require deliberate outbound design, such as NAT plus scoped NSG egress.
- Build and deploy stages must now coordinate on explicit object naming and bucket lifecycle rules.
- Runtime state migration becomes an explicit one-time operational step before OCI DevOps can own production rollout safely.
- Verification helpers must be maintained carefully so local Compose and OCI Podman-native execution do not drift semantically.

Risks:
- If the pipeline is allowed to deploy anything other than an explicit git reference, traceability will still be weak.
- If the deployment shell stage receives broader network or IAM access than necessary, the managed pipeline will just become a different form of over-privileged control plane.
- If Object Storage permissions are scoped too broadly, the release handoff bucket could become an unnecessary escalation path.
- If the remote runtime backend is missing or empty and the deploy stage is not guarded against that condition, OCI DevOps could attempt an unsafe runtime apply from an untracked state.
- If local and OCI verification backends diverge in behavior, engineers could get false confidence from a passing local run that does not reflect the CI path.

## Alternatives Considered

- Permanent deployment VM in OCI: rejected as the default because it creates a long-lived, manually maintained, high-value control-plane host with broad standing privileges.
- Continue using an operator laptop for private-network steps: rejected because it is not a solid or reproducible foundation for private OCI rollout.
- OCI DevOps managed `DELIVER_ARTIFACT` stages for release-bundle handoff: rejected for this path after repeated OCI-managed internal failures during artifact publication even when the build stage itself succeeded. The managed stage boundary is too opaque for a critical private rollout handoff.
