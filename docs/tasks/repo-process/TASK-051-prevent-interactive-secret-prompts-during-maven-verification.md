---
id: TASK-051
title: Prevent Interactive Secret Prompts During Maven Verification
status: done
category: repo-process
related_features:
  - SPEC-006
owner: @aattard
created: 2026-04-12
updated: 2026-04-12
---

## Summary

Ensure repository tests and automated verification do not block on `/dev/tty` secret prompts when they exercise operator helper scripts.

## Scope

- Define the non-interactive behavior expected when helper scripts are exercised from Maven tests or CI-style automation.
- Update the failing test coverage first so the regression is explicit.
- Change the helper-script path so automated invocations fail fast with a clear error instead of prompting.
- Keep manual operator prompting available for genuine interactive use.

## Out of Scope

- Replacing operator helper scripts with Java-native tooling.
- Changing production runtime secret handling.
- Changing the `VERIFY_DB_USERNAME` / `VERIFY_DB_PASSWORD` contract for the verification database.

## Acceptance Criteria

- [x] A repository test demonstrates that automated invocation does not block on `/dev/tty` prompts.
- [x] Helper-script automation fails fast with a clear non-interactive error when required secrets are missing.
- [x] Manual interactive use remains available outside automated verification.
- [x] `./mvnw clean verify` completes without prompting for repository helper-script secrets.
