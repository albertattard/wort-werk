---
id: SPEC-005
title: User Accounts, Authentication, and Learning Progress
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-08
---

## Problem

The quiz is currently anonymous and stateless per user. We cannot enforce user-specific sessions now, and we cannot track progress later without an auth and data foundation.

## Decision Constraints

- Database must be introduced before authentication and progress tracking.
- KeePass is not an identity provider; it can store credentials but cannot act as server-side auth.
- Current database choice: PostgreSQL.
- Progress and attempts are deferred to a separate workstream.
- Authentication approach for this phase: passkey-first WebAuthn login/registration with server-side session.
- Password-based login is not part of the target end state for this spec.
- WebAuthn relying party configuration must be explicit (`rpId`, origins), and production use requires HTTPS.

## Phased Scope

### Phase 1 (Current): Auth Foundation Only

- A learner can register/login/logout with passkeys (passwordless).
- Quiz access can be tied to authenticated session.
- No progress view, no adaptive noun selection, no attempt tracking.

### Phase 2 (Deferred): Learning Progress

- Track per-user answers and noun exposure.
- Prioritize unseen nouns, then weak nouns, then reinforcement nouns.
- Show per-user progress views.

## User-facing Behavior (Future Full Scope)

- A learner can register/login.
- The app tracks per-user answers and noun exposure.
- The quiz prioritizes:
  1. unseen nouns,
  2. weak nouns (high error rate / overdue),
  3. reinforcement nouns.

## Data Requirements

- Phase 1:
  - persistent users
  - persistent passkey credential records (credential id, public key material, sign counter, user binding)
  - persistent auth/session state
- Phase 2 (deferred):
  - persistent answer attempts
  - noun-level aggregates per user

## Ordered Implementation Plan

1. Add PostgreSQL infrastructure and migrations for auth baseline.
2. Add user model, WebAuthn credential model, and session boundaries.
3. Implement passkey registration and authentication (passwordless) for authenticated quiz sessions.
4. Add migration/operational docs for auth database setup.
5. In separate deferred stream, add attempts/progress/adaptive selection/progress UI.

## Acceptance Criteria

- [ ] PostgreSQL is integrated and migrations are versioned for auth + passkey credential baseline.
- [ ] Passwordless authentication (WebAuthn passkeys) is implemented end-to-end.
- [ ] No password hash storage is required for primary login flow.
- [ ] Auth-only slice explicitly excludes attempts/progress/adaptive-selection UI.
- [ ] Deferred progress workstream is tracked by separate tasks.
- [ ] `./mvnw clean verify` passes.
