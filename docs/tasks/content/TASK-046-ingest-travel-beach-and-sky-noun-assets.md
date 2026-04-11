---
id: TASK-046
title: Ingest Travel, Beach, and Sky Noun Assets
status: done
category: content
related_features:
  - SPEC-001
  - SPEC-004
owner: @aattard
created: 2026-04-10
updated: 2026-04-10
---

## Summary

Ingest the newly dropped travel, beach, sky, and public-place noun images in `assets/images/new` by normalizing technical filenames where needed, adding metadata rows, generating resized variants and audio files, and moving processed source images into categorized `assets/images/original`.

## Scope

- Normalize technical filenames for non-ASCII or semantically weak source names before sync.
- Add missing rows to `assets/articles.csv` for the new nouns and same-noun image variants.
- Use stable asset IDs and category assignments that match the categorized asset catalog.
- Run `tools/update-assets` to generate missing `420px` images and noun/answer audio files.
- Move processed files from `assets/images/new` to `assets/images/original/<category>/`.

## Out of Scope

- Runtime quiz behavior changes.
- Automatic article inference.
- Reworking unrelated auth, infrastructure, or documentation changes already present in the branch.

## Acceptance Criteria

- [x] All intended new `assets/images/new/*.png` files have corresponding rows in `assets/articles.csv`.
- [x] Non-ASCII or semantically weak technical stems are normalized before sync where required by the asset pipeline.
- [x] Same-noun variants use distinct stable IDs while preserving the intended learner-facing noun/article values.
- [x] Missing resized images are created under `assets/images/420/<category>/`.
- [x] Missing noun and answer audio files are created under `assets/audio`.
- [x] Processed new images are moved to `assets/images/original/<category>/`.
- [x] Baseline verification passes before the content changes are applied.
