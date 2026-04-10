---
id: ADR-0006
title: Use Stable Asset IDs and Category Directories
status: accepted
date: 2026-04-10
---

## Context

The image catalog has grown beyond a manageable flat directory layout. The existing workflow stores every source image in a single `assets/images/original` directory, every derived image in a single `assets/images/420` directory, and relies on technical filenames plus learner-facing noun text to coordinate metadata.

That approach creates several problems:

- flat folders do not scale as the catalog grows;
- technical filenames are doing double duty as learner-facing identifiers;
- duplicate noun forms are valid in German (`der Speckstreifen`, `die Speckstreifen`) but noun-only uniqueness checks break on them;
- tests and tooling need a stable identifier that survives filename normalization and noun changes.

## Decision

Adopt a structured asset catalog with:

- a stable `Id` column in `assets/articles.csv`;
- category directories under `assets/images/original/<category>/` and `assets/images/420/<category>/`;
- `assets/images/new/` as an inbox-only staging area;
- learner-facing noun/article values sourced from CSV metadata rather than inferred from technical filenames.

Technical filenames remain ASCII-safe and may use suffixes such as `-pl` for disambiguation. Category names are lowercase ASCII-safe directory names.

## Consequences

Positive:

- image browsing and review scale better with domain directories;
- duplicate learner-facing nouns are supported through unique IDs;
- tests can key off stable identifiers or image paths rather than noun text alone;
- the asset pipeline can validate catalog consistency more precisely.

Tradeoffs:

- the migration requires moving the existing image catalog;
- the asset sync tooling must recurse through directories and honor the new CSV schema;
- the CSV becomes more structured and requires operators to provide IDs and categories for new rows.
