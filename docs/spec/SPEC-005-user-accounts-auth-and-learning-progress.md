---
id: SPEC-005
title: User Accounts, Authentication, and Learning Progress
status: proposed
priority: high
owner: @aattard
last_updated: 2026-04-05
---

## Problem

The quiz is currently anonymous and stateless per user. We cannot track progress, prioritize unseen nouns, or target nouns answered incorrectly.

## Decision Constraints

- Database must be introduced before authentication and progress tracking.
- KeePass is not an identity provider; it can store credentials but cannot act as server-side auth.
- Preferred direction is passwordless authentication (passkeys/WebAuthn) with a recovery mechanism.

## User-facing Behavior

- A learner can register/login.
- The app tracks per-user answers and noun exposure.
- The quiz prioritizes:
  1. unseen nouns,
  2. weak nouns (high error rate / overdue),
  3. reinforcement nouns.

## Data Requirements

- Persistent users.
- Persistent auth credentials/session state.
- Persistent answer attempts and noun-level aggregates per user.

## Ordered Implementation Plan

1. Add database infrastructure and migrations (no auth yet).
2. Add user model and session boundaries.
3. Implement authentication (passkeys recommended).
4. Persist quiz attempts per authenticated user.
5. Build adaptive noun selection from progress data.
6. Add learner progress view (unseen/weak/mastered).
7. Add migration/backfill/operational docs.

## Acceptance Criteria

- [ ] Database is integrated and migrations are versioned.
- [ ] Authentication is implemented without introducing plaintext password storage.
- [ ] Quiz attempts are persisted per user.
- [ ] Adaptive selection uses per-user progress and is test-covered.
- [ ] Learner can view personal progress summary.
- [ ] `./mvnw clean verify` passes.
