---
id: TASK-039
title: Normalize Speck and Speckstreifen Asset Naming
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

Normalize both bacon-strip assets so the filenames use ASCII-safe technical stems while the learner-facing CSV rows use the proper singular and plural noun forms.

## Scope

- Keep the plural asset files on the `Speckstreifen-pl` stem.
- Rename the singular bacon-strip asset to an ASCII-safe `Speckstreifen` stem.
- Replace the generic singular `Speck` CSV row with the proper learner-facing noun and article for one bacon strip.
- Preserve the separate plural CSV row.
- Generate noun and answer audio files for the singular entry.

## Out of Scope

- Reprocessing unrelated new images in `assets/images/new`.
- Changing quiz runtime behavior.
- Inventing non-standard German plural forms.

## Acceptance Criteria

- [x] The plural bacon-strip asset no longer uses the `Specke` filename stem.
- [x] The singular bacon-strip asset no longer uses the generic `Speck` filename stem.
- [x] The renamed image paths are reflected correctly in `assets/articles.csv`.
- [x] The plural entry uses a proper learner-facing noun rather than `Specke`.
- [x] The singular entry uses the proper learner-facing noun rather than `Speck`.
- [x] Matching noun and answer audio files exist for the singular entry.
- [x] Baseline verification passes before the content change is applied.
