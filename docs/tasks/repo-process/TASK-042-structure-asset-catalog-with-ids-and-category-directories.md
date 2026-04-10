---
id: TASK-042
title: Structure Asset Catalog with IDs and Category Directories
status: done
category: repo-process
related_features:
  - SPEC-001
  - SPEC-004
owner: @aattard
created: 2026-04-10
updated: 2026-04-10
---

## Summary

Migrate the asset catalog from flat image directories and noun-only metadata assumptions to stable asset IDs, category directories, and a recursive asset sync workflow.

## Scope

- Add a stable `Id` column to `assets/articles.csv`.
- Organize source and derived images under category directories.
- Update runtime/test code and the asset pipeline to support the new schema and layout.
- Keep `assets/images/new` as an inbox-only staging directory for newly dropped images.
- Migrate the existing asset catalog and verification checks to the new structure.

## Out of Scope

- Changes to learner-facing quiz flow.
- Reworking unrelated auth or verification changes already present in the branch.
- Automatic category inference for new images.

## Acceptance Criteria

- [x] `assets/articles.csv` includes stable IDs for every row.
- [x] Source and derived images live under category directories instead of a single flat folder.
- [x] `tools/update-assets` supports the structured catalog and recursive directory layout.
- [x] Runtime/tests no longer assume learner-facing nouns are globally unique.
- [x] Repository docs describe the new asset organization model.
- [x] Baseline verification passes before implementation changes are applied.
