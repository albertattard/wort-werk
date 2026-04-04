---
id: TASK-017
title: Document Manual Let's Encrypt TLS Issuance and Renewal
status: done
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Document a practical runbook to issue and renew Let’s Encrypt certificates manually for `wortwerk.xyz` and bind them to the OCI Load Balancer HTTPS listener.

Superseded by `TASK-018` for Terraform-managed certificate installation.

## Scope

- Add a step-by-step Let’s Encrypt certificate issuance process using manual DNS challenge.
- Document OCI Certificate upload and Load Balancer HTTPS listener configuration.
- Document HTTP to HTTPS redirect behavior.
- Add a manual 90-day renewal checklist.
- Include validation commands to verify HTTPS certificate health after each renewal.
- Document certbot writable directory usage for non-root local execution.
- Document copy/paste Terraform command to fetch `load_balancer_id` for OCI CLI TLS operations.

## Assumptions

- Domain DNS remains managed outside Terraform.
- Manual renewal is acceptable for now (no ACME automation in this task).
- OCI Load Balancer already exists and fronts the application.
- Certificate/private key material must remain outside Terraform state.

## Acceptance Criteria

- [x] Runbook includes initial certificate issuance steps for apex and `www` hostnames.
- [x] Runbook includes exact OCI Console wiring steps for HTTPS listener and redirect.
- [x] Runbook includes OCI CLI commands to create certificate and attach it to HTTPS listener.
- [x] Runbook includes a repeatable manual renewal flow for every 90 days.
- [x] Runbook includes post-renewal validation commands.
- [x] Runbook shows non-root certbot directory configuration and resulting certificate file paths.
- [x] Runbook includes Terraform command to retrieve `load_balancer_id` for CLI certificate upload.
- [x] `./mvnw clean verify` passes after changes.
