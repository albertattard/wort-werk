# ADR-0011: Use OCI DevOps Managed Private Release Pipelines

## Status
Accepted

## Context

Wort-Werk now has private OCI networking for runtime and database access, plus a dedicated non-admin runtime database role that must be bootstrapped from inside the private network. That makes operator-laptop-driven release execution an awkward and brittle trust boundary.

One option is to introduce a permanent OCI VM that can pull the repository, build the application, push images, run Terraform, and execute private PostgreSQL bootstrap steps. That would improve reachability, but it would also centralize too much standing privilege in a long-lived machine that becomes the deployment control plane.

OCI DevOps already provides managed build and deployment pipelines. Build runs can be started against a selected branch and commit, and deployment shell stages can run on a managed container-instance host inside a selected subnet using the pipeline resource principal.

## Decision

Adopt OCI DevOps managed pipelines as the default Wort-Werk release foundation instead of introducing a permanent manually administered deployment VM.

The intended structure is:

1. Use an OCI DevOps build pipeline to check out a specific git reference, run verification, and publish a commit-traceable image.
2. Use an OCI DevOps deployment pipeline to execute private-network rollout steps from inside OCI.
3. Run private PostgreSQL bootstrap steps from a deployment shell stage inside a private subnet rather than from an operator laptop.
4. Prefer ephemeral or OCI-managed execution over long-lived general-purpose deployment hosts.

## Consequences

Positive:
- Release execution becomes reproducible and tied to explicit repository state instead of a mutable local workspace.
- Private-network deployment steps no longer depend on a human reaching into the VCN from an ad hoc machine.
- OCI-managed identity can replace some static operator credential handling.

Negative:
- OCI DevOps resources, permissions, and pipeline definitions add new infrastructure surface area.
- Build and deployment concerns must be modeled explicitly instead of hidden in local shell scripts.

Risks:
- If the pipeline is allowed to deploy anything other than an explicit git reference, traceability will still be weak.
- If the deployment shell stage receives broader network or IAM access than necessary, the managed pipeline will just become a different form of over-privileged control plane.

## Alternatives Considered

- Permanent deployment VM in OCI: rejected as the default because it creates a long-lived, manually maintained, high-value control-plane host with broad standing privileges.
- Continue using an operator laptop for private-network steps: rejected because it is not a solid or reproducible foundation for private OCI rollout.
