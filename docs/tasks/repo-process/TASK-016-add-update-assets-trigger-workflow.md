---
id: TASK-016
title: Add Update Assets Trigger Workflow
status: done
category: repo-process
related_features:
  - SPEC-004
owner: @aattard
created: 2026-04-04
updated: 2026-04-05
---

## Summary

Add a triggerable workflow (`update assets`) that synchronizes CSV rows with images and generates missing audio files.

## Scope

- Add `tools/update-assets` automation command.
- Implement `tools/update-assets` as Java shebang script.
- Keep `assets/articles.csv` as the metadata source (no overrides file).
- Support drop-in new source images via `assets/images/new`.
- Update `AGENTS.md` with trigger phrase mapping.
- Document behavior and failure mode for missing metadata.

## Assumptions

- Article metadata for newly added images is provided explicitly (no guessing).
- `tools/tts` is available and configured.

## Acceptance Criteria

- [x] Running `./tools/update-assets` updates `assets/articles.csv` deterministically.
- [x] Running `./tools/update-assets` creates missing audio files.
- [x] Unknown images without metadata fail with a clear actionable message.
- [x] `AGENTS.md` documents trigger phrase `update assets`.
- [x] `./mvnw clean verify` passes after changes.
