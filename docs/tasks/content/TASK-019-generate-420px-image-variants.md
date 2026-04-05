---
id: TASK-019
title: Generate 420px Image Variants While Preserving Originals
status: done
category: content
related_features:
  - SPEC-004
owner: @aattard
created: 2026-04-04
updated: 2026-04-04
---

## Summary

Create resized image variants for every source image under `assets/images/original` with fixed height `420px`, without modifying original files.

## Scope

- Create a dedicated output directory for resized images.
- Generate one resized image per source image in `assets/images/original`.
- Keep filenames unchanged between source and resized variants.
- Preserve source image files without modification.
- Update `assets/articles.csv` image paths to point to resized images under `assets/images/420`.

## Assumptions

- Width should scale proportionally based on original image aspect ratio.
- PNG output format remains unchanged.

## Acceptance Criteria

- [x] Directory `assets/images/420` exists.
- [x] Every image in `assets/images/original` has a corresponding image in `assets/images/420`.
- [x] Each generated image has height `420px`.
- [x] Original images in `assets/images/original` remain unchanged.
- [x] `assets/articles.csv` image paths reference `assets/images/420`.
- [x] `./mvnw clean verify` passes after changes.
