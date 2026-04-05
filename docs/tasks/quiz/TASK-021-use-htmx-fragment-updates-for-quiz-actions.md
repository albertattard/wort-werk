---
id: TASK-021
title: Use HTMX Fragment Updates for Quiz Actions
status: pending
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Wire quiz actions to HTMX so `answer`, `next`, and `restart` update only the interaction fragment and avoid full-page reloads.

## Scope

- Add HTMX attributes to quiz action forms/buttons in the interaction fragment.
- Ensure actions target and swap only `#quiz-interaction`.
- Keep non-HTMX fallback behavior working (redirect full-page).
- Update/extend functional test coverage to verify fragment-based interaction behavior.

## Assumptions

- Current fragment endpoint responses in `QuizController` remain the source for HTMX requests.
- Audio playback logic must continue to work after fragment swaps.

## Acceptance Criteria

- [ ] Clicking `der/die/das` sends HTMX request and updates only the interaction fragment.
- [ ] Automatic `/next` submission after correct-audio completion uses HTMX fragment update.
- [ ] Restart action uses HTMX fragment update.
- [ ] Full-page non-HTMX fallback still works.
- [ ] Functional tests cover HTMX interaction flow.
- [ ] `./mvnw clean verify` passes after implementation.
