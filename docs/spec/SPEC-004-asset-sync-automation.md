---
id: SPEC-004
title: Asset Sync Automation
status: done
priority: medium
owner: @aattard
last_updated: 2026-04-10
---

## Problem

Image assets are added frequently and `assets/articles.csv` plus audio files can drift out of sync, causing runtime/test failures.

## User-facing Behavior

A single operator trigger phrase (`update assets`) runs a deterministic workflow that:
- syncs `assets/articles.csv` with source images in `assets/images/original/<category>/` and `assets/images/new`
- keeps one CSV row per image
- keeps one stable asset `Id` per CSV row
- generates missing noun/answer audio files
- allows ASCII-safe technical filename suffixes such as `-pl` for disambiguation while keeping learner-facing noun/article values in `assets/articles.csv`
- allows neutral ASCII-safe numeric variant suffixes such as `-01` and `-02` when multiple images intentionally share the same learner-facing noun
- allows operators to normalize technical filename stems before sync when dropped images use non-ASCII or non-standard source names
- maintains derivative image copies under:
  - `assets/images/420/<category>/` with fixed height `420px`
  - originals preserved under `assets/images/original/<category>/`
  - images dropped in `assets/images/new` are processed and moved into the category path defined by `assets/articles.csv`

## Inputs/Outputs

Input:
- source image files under `assets/images/original/<category>/` and `assets/images/new`
- existing `assets/articles.csv`
- manual `Id`/noun/article/category metadata updates in `assets/articles.csv` for newly added source images

Output:
- updated `assets/articles.csv`
- missing audio files created in `assets/audio`
- missing resized images created in `assets/images/420/<category>/` from `assets/images/original/<category>/`
- images moved from `assets/images/new` to `assets/images/original/<category>/` after successful sync
- explicit failure listing images that are missing required metadata

## Acceptance Criteria

- [x] Repository contains executable automation command for asset sync.
- [x] Asset-sync automation is implemented as Java shebang script.
- [x] Trigger phrase `update assets` is documented in `AGENTS.md`.
- [x] Automation fails fast when new images are missing article metadata.
- [x] Automation generates missing noun and answer audio via `tools/tts`.
- [x] Repository includes resized image variants in `assets/images/420` while keeping originals unchanged.
- [x] Repository stores source and derivative image sets in separate directories (`original` and `420`).
- [x] Automation generates missing resized `420px` image variants from source images.
- [x] CSV rows carry stable asset IDs independent of learner-facing noun text.
- [x] Asset sync supports recursive category directories under `original/` and `420/`.

## Non-goals

- Automatic article inference for unknown nouns.
