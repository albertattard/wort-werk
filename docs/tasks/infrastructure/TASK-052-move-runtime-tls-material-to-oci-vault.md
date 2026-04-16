---
id: TASK-052
title: Move Runtime TLS Material to OCI Vault
status: done
category: infrastructure
related_features:
  - SPEC-003
  - SPEC-008
owner: @aattard
created: 2026-04-16
updated: 2026-04-16
---

## Summary

Replace runtime Terraform's dependency on project-local PEM files with OCI Vault-backed TLS inputs so OCI DevOps can perform the full HTTPS rollout without laptop-local certificate material.

## Scope

- Replace runtime Terraform file-path TLS inputs with Vault secret OCID inputs.
- Resolve TLS certificate content inside Terraform from OCI Vault at apply time.
- Keep TLS issuance and renewal manual, but move the resulting PEM material into OCI Vault rather than repository-local directories.
- Extend the OCI DevOps deployment contract so the private rollout stage receives the TLS secret OCIDs it needs.
- Extend DevOps least-privilege secret-read policy to include the TLS secrets required for runtime apply.
- Update runtime and OCI deployment documentation to describe the Vault-backed TLS workflow.

## Constraints

- Normal production rollout must remain OCI DevOps-driven rather than laptop-driven.
- TLS private key material must not be committed to git or required in the OCI deploy runner workspace.
- Secret access for OCI DevOps must stay scoped to the specific TLS secret OCIDs rather than broad compartment-wide secret reads.
- The runtime stack must continue to support HTTPS-only load balancer configuration and HTTP to HTTPS redirect.

## Acceptance Criteria

- [x] Runtime Terraform no longer reads TLS certificate files from `infrastructure/oci/runtime/tls/...`.
- [x] Runtime Terraform reads public certificate, private key, and optional CA certificate content from OCI Vault secret bundles.
- [x] OCI DevOps deployment receives the TLS secret OCIDs required for runtime apply.
- [x] OCI DevOps runner least-privilege policy includes only the configured TLS secret OCIDs in addition to the existing release secrets.
- [x] Repository docs describe how to create or rotate the TLS secrets in OCI Vault before runtime or OCI DevOps rollout.
- [x] `./mvnw clean verify` passes after the change.
