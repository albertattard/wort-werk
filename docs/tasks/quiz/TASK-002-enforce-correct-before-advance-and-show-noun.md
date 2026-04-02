---
id: TASK-002
title: Enforce Correct Selection Before Advancing and Show Noun
status: done
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-02
updated: 2026-04-02
---

## Summary

Align quiz interaction with the updated learning flow: show the noun, keep the same object on wrong selections, and only advance after a correct selection.

## Scope

- Show noun text below the current image.
- On wrong selection:
  - keep the same object active,
  - show feedback,
  - highlight the correct article.
- On correct selection:
  - advance immediately to the next randomized entry.

## Assumptions

- Question content continues to be loaded from `assets/articles.csv`.
- Randomization means a randomized order per quiz session without repeating entries in that session.

## Acceptance Criteria

- [x] Noun is visible for the current image prompt.
- [x] Wrong selection does not advance the round.
- [x] Correct article is visually highlighted after a wrong selection.
- [x] Correct selection advances immediately to the next prompt.
- [x] `./mvnw clean verify` passes.

## Notes

This task was added to backfill process tracking after implementation and test verification.
