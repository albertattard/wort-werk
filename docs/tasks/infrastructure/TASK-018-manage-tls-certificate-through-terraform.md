---
id: TASK-018
title: Manage TLS Certificate and HTTPS Listener Through Terraform
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Move TLS certificate handling into runtime Terraform so certificate bundle, HTTPS listener and HTTP to HTTPS redirect are all applied via IaC.

## Scope

- Add runtime Terraform variables for certificate file paths and TLS behavior.
- Add OCI Load Balancer certificate resource in runtime Terraform.
- Add HTTPS listener managed by runtime Terraform.
- Add HTTP to HTTPS redirect rule set managed by runtime Terraform.
- Update runtime outputs and deployment docs for TLS-first access.
- Define project-local certificate directory conventions.
- Remove optional TLS toggle and enforce always-on HTTPS in runtime Terraform.

## Assumptions

- Let's Encrypt issuance remains manual (DNS challenge), but resulting certificate files are placed in the repository runtime TLS directory.
- Operators accept that certificate/private key content is read by Terraform.

## Acceptance Criteria

- [x] Runtime Terraform can create/update load balancer certificate from project-local PEM files.
- [x] Runtime Terraform creates HTTPS listener and serves traffic through TLS.
- [x] HTTP listener always redirects to HTTPS.
- [x] Runtime outputs are HTTPS-only (`access_url` and `https_access_url`).
- [x] Runtime no longer exposes a `tls_enabled` variable.
- [x] Deployment docs include copy/paste commands for certificate placement and Terraform apply.
- [x] `./mvnw clean verify` passes after changes.
