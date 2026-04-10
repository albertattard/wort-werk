---
id: TASK-023
title: Sync Missing Nouns and Regenerate Missing Derived Assets
status: done
category: content
related_features:
  - SPEC-004
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Sync `assets/articles.csv` with newly added source images and generate any missing derived assets (`420px` images and audio files).

## Scope

- Remove `assets/articles-overrides.csv` and keep `assets/articles.csv` as the single metadata source.
- Support a drop-in source directory `assets/images/new` for newly added images.
- Update asset-sync automation to generate missing resized images in `assets/images/420`.
- Run automation to refresh `assets/articles.csv` and generate missing audio.
- Verify repository tests and full verification pass.

## Assumptions

- `assets/images/original` remains the source-of-truth image catalog.
- Images dropped in `assets/images/new` will be moved into `assets/images/original` on successful sync.
- Learner-facing noun values come from `assets/articles.csv`; later filename disambiguation should stay technical rather than inventing new noun forms.

## Acceptance Criteria

- [x] Missing noun rows are present in `assets/articles.csv` for all source images.
- [x] Missing resized images are generated in `assets/images/420`.
- [x] Missing noun and answer audio files are generated in `assets/audio`.
- [x] New images can be placed in `assets/images/new` and are moved into `assets/images/original` after successful sync.
- [x] `assets/articles-overrides.csv` is removed from the workflow.
- [x] `./mvnw clean verify` passes.
