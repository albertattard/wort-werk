---
id: TASK-022
title: Separate Original and Derived Image Directories
status: done
category: content
related_features:
  - SPEC-004
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Move source images into a dedicated `original` directory and keep resized variants under `420` so the asset pipeline has explicit source/derived separation.

## Scope

- Move tracked source PNG files from `assets/images` to `assets/images/original`.
- Keep resized derivatives in `assets/images/420`.
- Update asset sync tooling to read source images from `assets/images/original`.
- Update CSV/catalog validation tests to use `assets/images/original` as image catalog source.

## Assumptions

- Learner-facing image paths in `assets/articles.csv` continue pointing to resized assets in `assets/images/420`.
- Newly added untracked images are ignored unless explicitly requested.

## Acceptance Criteria

- [x] Source images reside under `assets/images/original`.
- [x] `assets/images/420` remains the derivative output location.
- [x] `tools/update-assets` reads source images from `assets/images/original`.
- [x] Repository tests validate CSV entries against `assets/images/original`.
- [x] `./mvnw clean verify` passes after changes.
