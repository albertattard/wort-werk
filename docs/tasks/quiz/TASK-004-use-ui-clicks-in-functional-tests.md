---
id: TASK-004
title: Use UI Clicks in Functional Tests
status: done
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-02
updated: 2026-04-02
---

## Summary

Replace direct `fetch`-based POST helpers in functional tests with real UI button clicks for article selection.

## Scope

- Remove helper that posts answer requests directly from page JavaScript.
- Click article buttons by `data-testid`.
- Add deterministic waits so HTMX updates complete before assertions.

## Assumptions

- UI click interactions remain stable with explicit wait conditions.
- This does not change quiz behavior, only test interaction strategy.

## Acceptance Criteria

- [x] Functional tests no longer use direct `fetch` posts for answer submission.
- [x] Article selection in functional tests is performed via button clicks.
- [x] `./mvnw verify` passes.

## Notes

To remove click-handling fragility, answer/restart interactions use native HTML form submission rather than HTMX interception.
