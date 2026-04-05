---
id: TASK-024
title: Roll Out User Auth and Progress Tracking
status: pending
category: quiz
related_features:
  - SPEC-005
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Introduce user login and per-user learning progress in ordered vertical slices, starting with database foundation.

## Scope

- Define and implement the step-by-step rollout plan from SPEC-005.
- Keep each step independently verifiable and releasable.
- Preserve existing quiz behavior while adding user-aware behavior incrementally.

## Ordered Steps

1. Database Foundation
- Add PostgreSQL support, local/dev profile, Flyway, baseline schema.
- Tables: `users`, `sessions`/auth state, `answer_attempts`, `noun_progress`.

2. Authentication Slice
- Add login/register/logout flows and protected quiz session.
- Recommended: WebAuthn passkeys (passwordless).
- Add fallback/recovery path (e.g., magic link) as a follow-up.

3. Progress Persistence Slice
- Persist every answer attempt with correctness and noun metadata.
- Update noun-level aggregates per user.

4. Adaptive Selection Slice
- Implement selector order: unseen -> weak -> reinforcement.
- Add deterministic tests for selector behavior.

5. Progress UX Slice
- Add learner view for unseen/weak/mastered nouns.
- Show recent mistakes and targeted practice.

6. Operational Hardening
- Add migration/rollback notes and production config docs.
- Verify full pipeline and deployment compatibility.

## Acceptance Criteria

- [ ] Ordered steps are implemented one at a time with linked sub-tasks.
- [ ] Each slice has tests and clear rollback path.
- [ ] Full verification passes after each completed slice.
