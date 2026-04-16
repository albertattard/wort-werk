# ADR-0012: Store Runtime TLS Material in OCI Vault

## Status
Accepted

## Context

Wort-Werk runtime Terraform currently configures the OCI Load Balancer certificate by reading PEM files from `infrastructure/oci/runtime/tls/...`. That worked for laptop-driven applies, but it breaks the repository direction established by OCI DevOps-managed private release pipelines.

The OCI DevOps deploy runner does not have the operator's local TLS files. As a result, the rollout can build and publish a verified image successfully and still fail during runtime apply because `file(var.tls_private_key_path)` and similar calls cannot resolve the certificate material in the managed runner workspace.

This is not just a tooling inconvenience. It means HTTPS rollout still depends on laptop-local deployment state even though OCI DevOps is intended to be the sole supported production release path.

## Decision

Adopt OCI Vault as the source of truth for runtime TLS certificate material used by Terraform-managed OCI Load Balancer HTTPS configuration.

The intended model is:

1. Continue issuing and renewing the certificate outside Terraform.
2. Store the resulting public certificate, private key, and optional CA chain in OCI Vault secrets instead of repository-local PEM paths.
3. Pass the relevant TLS secret OCIDs into the runtime and DevOps stacks as stable deployment inputs.
4. Have runtime Terraform read the secret bundles at apply time and supply the resolved PEM content to `oci_load_balancer_certificate`.
5. Extend the OCI DevOps runner's least-privilege secret-read policy to include only the configured TLS secret OCIDs.

## Consequences

Positive:
- OCI DevOps can perform the full HTTPS rollout without laptop-local certificate files.
- TLS private key material remains outside git and outside the managed runner workspace.
- The HTTPS deployment contract becomes consistent with the existing OCI Vault model already used for database secrets.
- Secret access remains auditable and scoped to explicit OCIDs.

Negative:
- Certificate rotation becomes a two-step operational process: renew the cert, then update the OCI Vault secrets.
- Runtime and DevOps stack configuration gains additional secret OCID inputs.
- Terraform apply now depends on OCI Vault availability for TLS material in the same way it already depends on OCI for other deployment inputs.

Risks:
- If TLS secret-read policy scope is too broad, the release runner gains unnecessary secret access.
- If certificate renewal updates only some of the required TLS secrets, the next rollout can fail with mismatched material.
- If we keep the old file-path workflow documented in parallel, operators will continue using an unsupported release path and drift will persist.

## Alternatives Considered

- Keep repository-local PEM files and copy them into the deploy runner: rejected because it recreates a laptop-dependent control path and spreads sensitive key material into transient workspaces.
- Stop managing the load balancer certificate through Terraform and update it manually: rejected because it weakens reproducibility and leaves HTTPS state outside the OCI DevOps rollout contract.
- Use OCI Certificates service immediately instead of OCI Vault secrets: not chosen for this iteration because the repository already has an established Vault secret workflow and least-privilege secret-read model. That remains a valid future refinement if certificate lifecycle automation becomes a priority.
