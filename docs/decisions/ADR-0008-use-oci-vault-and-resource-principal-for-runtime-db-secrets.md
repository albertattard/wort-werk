# ADR-0008: Use OCI Vault and Resource Principals for Runtime DB Secrets

## Status
Accepted

## Context

Wort-Werk now needs a managed PostgreSQL deployment in OCI. The application requires a database password at runtime, but storing that password in version control, container images, or Terraform-managed plaintext environment variables would weaken the security model.

## Decision

Adopt the following secret-delivery model for OCI runtime database access:

1. Store database passwords in OCI Vault.
2. Provision OCI Vault and its key through Terraform, but create or rotate secret contents outside Terraform.
3. Grant the Wort-Werk Container Instance permission to read the runtime database password secret bundle through a dynamic group and compartment policy.
4. Have the application fetch the runtime DB password from OCI Vault at startup by using the container instance resource principal.
5. Keep TLS in transit enabled for application-to-database connections, with the PostgreSQL CA certificate passed from foundation outputs into runtime configuration.

## Consequences

Positive:
- Production DB secrets stay out of version control.
- Production DB secrets do not need to be hard-coded in container images.
- Runtime secret access is scoped to OCI-managed identity instead of static local files.

Negative:
- Deployment becomes a two-step flow: provision Vault first, then create or rotate secrets, then enable DB creation and runtime rollout.
- The application startup path now depends on OCI Vault availability when runtime secret lookup is enabled.

Risks:
- Secret rotation must stay coordinated with the dedicated runtime-role bootstrap step, otherwise OCI Vault and PostgreSQL credentials can drift.

## Alternatives Considered

- Store runtime DB password in Terraform variables and inject directly into the container: simpler, but weaker because the secret would flow through infrastructure state and runtime config more directly.
- Store runtime DB password in the repository or container image: rejected.
