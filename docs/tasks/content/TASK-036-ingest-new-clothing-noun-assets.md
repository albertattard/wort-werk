---
id: TASK-036
title: Ingest New Clothing Noun Assets
status: done
category: content
related_features:
  - SPEC-001
  - SPEC-004
owner: @aattard
created: 2026-04-09
updated: 2026-04-09
---

## Summary

Ingest the newly dropped clothing images in `assets/images/new` by adding metadata rows, generating resized variants and audio files, and moving the processed source images into `assets/images/original`.

## Scope

- Add missing rows to `assets/articles.csv` for the new clothing nouns.
- Normalize new asset filenames to ASCII-safe paths where required by the asset pipeline.
- Run `tools/update-assets` to generate missing `420px` images and noun/answer audio files.
- Move processed files from `assets/images/new` to `assets/images/original`.

## Out of Scope

- Runtime quiz behavior changes.
- Automatic article inference.
- Removing curated plural/common-form nouns from this ingestion batch.

## Acceptance Criteria

- [x] All new `assets/images/new/*.png` files have corresponding rows in `assets/articles.csv`.
- [x] Missing resized images are created under `assets/images/420`.
- [x] Missing noun and answer audio files are created under `assets/audio`.
- [x] Processed new images are moved to `assets/images/original`.
- [x] Baseline verification passes before the content changes are applied.
