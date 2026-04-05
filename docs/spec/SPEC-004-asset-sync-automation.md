---
id: SPEC-004
title: Asset Sync Automation
status: done
priority: medium
owner: @aattard
last_updated: 2026-04-04
---

## Problem

Image assets are added frequently and `assets/articles.csv` plus audio files can drift out of sync, causing runtime/test failures.

## User-facing Behavior

A single operator trigger phrase (`update assets`) runs a deterministic workflow that:
- syncs `assets/articles.csv` with source images in `assets/images/original`
- keeps one CSV row per image
- generates missing noun/answer audio files
- maintains derivative image copies under:
  - `assets/images/420` with fixed height `420px`
  - originals preserved under `assets/images/original`

## Inputs/Outputs

Input:
- source image files under `assets/images/original`
- existing `assets/articles.csv`
- optional overrides file `assets/articles-overrides.csv` for new nouns/articles

Output:
- updated `assets/articles.csv`
- missing audio files created in `assets/audio`
- explicit failure listing images that are missing article metadata

## Acceptance Criteria

- [x] Repository contains executable automation command for asset sync.
- [x] Asset-sync automation is implemented as Java shebang script.
- [x] Trigger phrase `update assets` is documented in `AGENTS.md`.
- [x] Automation fails fast when new images are missing article metadata.
- [x] Automation generates missing noun and answer audio via `tools/tts`.
- [x] Repository includes resized image variants in `assets/images/420` while keeping originals unchanged.
- [x] Repository stores source and derivative image sets in separate directories (`original` and `420`).

## Non-goals

- Automatic article inference for unknown nouns.
