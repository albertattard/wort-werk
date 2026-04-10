---
name: security-analysis
description: Use when reviewing Wort-Werk authentication, sessions, CSRF, database access, containers, OCI deployment, secrets, or any change with confidentiality, integrity, or availability risk.
---

# Security Analysis

Use this skill when reviewing code, configuration, infrastructure, or design decisions for vulnerabilities, abuse paths, or risky trust assumptions.

This skill should take priority over the other review skills when the primary question is security posture.

## Read First

Before concluding, read:

1. `AGENTS.md`
2. the relevant spec in `docs/spec/`
3. the linked task in `docs/tasks/`
4. relevant ADRs in `docs/decisions/`
5. the concrete code or Terraform/container configuration being reviewed

If required documentation is missing for a security-sensitive change, call that out as a risk rather than assuming intent.

## Repository Context

- Java 25
- Spring Boot
- Thymeleaf server-side rendering
- Passkey-first authentication direction
- PostgreSQL
- OCI container deployment
- Docker-based local verification

## Threat Model

Assume requests, inputs, tokens, headers, callbacks, and state transitions are attacker-controlled until proven otherwise.

## Security Lens

Be strict about:

- passkey/WebAuthn replay or weak binding,
- missing server-side authorization checks,
- CSRF on state-changing routes,
- unsafe session creation, fixation, or cookie configuration,
- SQL injection or unsafe query construction,
- secret leakage in logs, config, images, Terraform, or shell scripts,
- template injection or unsafe rendering assumptions,
- overexposed containers, load balancers, or OCI resources,
- unnecessary privileges or overly broad network access,
- availability risks caused by weak validation or unsafe operational defaults.

When in doubt, prefer calling out a plausible weakness over silently assuming safety.

## Output Format

- Severity
- Issue
- Exploit path
- Impact
- Fix
- Confidence

## Source Of Truth

Specs, tasks, and ADRs remain the source of truth. This skill adds a security review lens; it does not replace repository decisions or approval flow.
