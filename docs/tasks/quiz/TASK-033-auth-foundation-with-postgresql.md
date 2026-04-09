---
id: TASK-033
title: Implement Auth Foundation with PostgreSQL
status: done
category: quiz
related_features:
  - SPEC-005
owner: @aattard
created: 2026-04-06
updated: 2026-04-07
---

## Summary

Implement the auth-only foundation using PostgreSQL and Spring Security, while explicitly deferring progress and attempts tracking to a separate stream.

## Scope

- Add PostgreSQL datasource configuration for local/dev and app runtime.
- Add Flyway and baseline migration for auth entities.
- Add minimal `users` schema (and any auth/session support tables needed by chosen approach).
- Implement register/login/logout flow with hashed credentials.
- Protect quiz routes behind authenticated session (as agreed in implementation design).

## Out of Scope

- Attempt persistence.
- Noun progress aggregation.
- Adaptive noun selection.
- Progress dashboards/views.
- Passkeys/WebAuthn.

## Acceptance Criteria

- [x] App starts with PostgreSQL configuration and Flyway migrations applied.
- [x] Register/login/logout flow works end-to-end.
- [x] Credentials are stored as hashes (no plaintext passwords).
- [x] Existing quiz behavior remains functionally intact for authenticated users.
- [x] Progress/attempt/adaptive logic remains out of this task.
- [x] `./mvnw clean verify` passes.
