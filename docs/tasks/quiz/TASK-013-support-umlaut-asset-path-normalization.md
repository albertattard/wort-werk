---
id: TASK-013
title: Support Umlaut Asset Path Normalization
status: done
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Fix static asset loading for nouns with umlauts by using ASCII-safe asset filenames and paths in production CSV.

## Scope

- Add a regression test that enforces ASCII-safe asset paths in `assets/articles.csv`.
- Rename affected image/audio files to ASCII-safe names (`Kaese`, `Loeffel`).
- Update `assets/articles.csv` paths while keeping learner-facing nouns unchanged.

## Assumptions

- Different platforms may normalize Unicode filenames differently.
- ASCII-safe asset paths avoid Unicode normalization ambiguity during static file resolution.

## Acceptance Criteria

- [x] A test fails before the fix for non-ASCII asset paths in production CSV.
- [x] Production CSV uses ASCII-safe image and audio paths.
- [x] Existing quiz behavior remains unchanged.
- [x] `./mvnw clean verify` passes.
