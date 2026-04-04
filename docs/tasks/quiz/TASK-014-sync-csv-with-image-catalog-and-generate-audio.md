---
id: TASK-014
title: Sync CSV with Image Catalog and Generate Audio
status: done
category: content
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Ensure `assets/articles.csv` contains one row per image in `assets/images` and generate noun + answer audio files for newly added nouns.

## Scope

- Add missing image nouns to `assets/articles.csv` with correct German articles.
- Generate missing audio files using `tools/tts`:
  - noun audio (`assets/audio/<Noun>.mp3`)
  - answer audio (`assets/audio/<article> <Noun>.mp3`)
- Add a regression test to enforce image catalog and CSV alignment.

## Assumptions

- The image filename (without extension) is the noun label used in CSV.
- Existing learner-facing noun text remains German-only.

## Acceptance Criteria

- [x] CSV includes all images from `assets/images`.
- [x] Missing noun and answer audio files are generated for newly added nouns.
- [x] Automated test enforces CSV/image coverage.
- [x] `./mvnw clean verify` passes.
