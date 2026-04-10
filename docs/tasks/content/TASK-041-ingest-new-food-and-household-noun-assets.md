---
id: TASK-041
title: Ingest New Food and Household Noun Assets
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

Ingest the newly dropped mixed noun images in `assets/images/new` by normalizing technical filenames where needed, adding metadata rows, generating resized variants and audio files, and moving processed source images into `assets/images/original`.

## Scope

- Normalize technical filename stems when the dropped names are non-ASCII or not standard German stems for the learner-facing noun.
- Add missing rows to `assets/articles.csv` for the new nouns.
- Run `tools/update-assets` to generate missing `420px` images and noun/answer audio files.
- Move processed files from `assets/images/new` to `assets/images/original`.

## Out of Scope

- Runtime quiz behavior changes.
- Automatic article inference.
- Reworking unrelated auth, verification, or documentation changes already present in the branch.

## Acceptance Criteria

- [x] All intended new `assets/images/new/*.png` files have corresponding rows in `assets/articles.csv`.
- [x] Non-ASCII or non-standard technical stems are normalized before sync where required by the asset pipeline.
- [x] Missing resized images are created under `assets/images/420`.
- [x] Missing noun and answer audio files are created under `assets/audio`.
- [x] Processed new images are moved to `assets/images/original`.
- [x] Baseline verification passes before the content changes are applied.
