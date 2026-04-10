---
id: TASK-037
title: Ingest New Kitchen Noun Asset
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

Ingest the newly dropped `Spatel` image in `assets/images/new` by adding metadata, generating the resized variant and audio files, and moving the processed source image into `assets/images/original`.

## Scope

- Add the missing `Spatel` row to `assets/articles.csv`.
- Run `tools/update-assets` to generate the missing `420px` image and noun/answer audio files.
- Move the processed file from `assets/images/new` to `assets/images/original`.

## Out of Scope

- Runtime quiz behavior changes.
- Automatic article inference.
- Changes to unrelated auth, template, or infrastructure work in the current branch.

## Acceptance Criteria

- [x] `assets/images/new/Spatel.png` has a corresponding row in `assets/articles.csv`.
- [x] Missing resized image is created under `assets/images/420`.
- [x] Missing noun and answer audio files are created under `assets/audio`.
- [x] Processed new image is moved to `assets/images/original`.
- [x] Baseline verification passes before the content change is applied.
