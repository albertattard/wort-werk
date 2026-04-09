---
id: TASK-035
title: Ingest New School Noun Assets
status: done
category: content
related_features:
  - SPEC-004
owner: @aattard
created: 2026-04-09
updated: 2026-04-09
---

## Summary

Ingest newly dropped images in `assets/images/new` by adding missing metadata, generating resized variants and audio files, and moving sources into `assets/images/original`.

## Scope

- Add missing rows to `assets/articles.csv` for the newly added school nouns.
- Run `tools/update-assets` to generate missing `420px` images and noun/answer audio files.
- Move processed files from `assets/images/new` to `assets/images/original`.

## Out of Scope

- Article auto-inference.
- Changes to quiz runtime behavior.
- Progress/auth features.

## Acceptance Criteria

- [x] All new `assets/images/new/*.png` files have corresponding rows in `assets/articles.csv`.
- [x] Missing resized images are created under `assets/images/420`.
- [x] Missing noun and answer audio files are created under `assets/audio`.
- [x] Processed new images are moved to `assets/images/original`.
- [x] `./mvnw clean verify` passes.
