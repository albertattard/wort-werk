---
id: TASK-02-0003
title: Reject invalid article content predictably
status: blocked
milestone: content_model_and_validation
depends_on: [TASK-02-0001, TASK-02-0002]
blocks: [TASK-02-0004]
updated: 2026-09-13
---

## Scope

Define and implement deterministic collection-level content validation for loaded article records. Validate IDs and declared local asset paths without adding UI behavior or a separate pre-Flutter validation tool.

## Completion criteria

- Duplicate, blank, or malformed IDs are rejected.
- Blank noun text and invalid declared image, noun-audio, or answer-audio paths are rejected.
- The repository exposes validation failures predictably for callers and tests.
- Validation stops at the first detected failure and returns no partial collection.
- Unit tests cover each invalid-content category and a valid collection.

## Evidence

Blocked by TASK-02-0001 and TASK-02-0002.

## Decisions and blockers

TASK-02-0001 rejects missing/wrongly typed properties and unsupported raw article values while mapping them to `GermanArticle`. This task requires `noun` to contain at least one non-whitespace character while preserving its authored text. It requires each ID and category to match the lowercase ASCII slug grammar `[a-z0-9]+(?:-[a-z0-9]+)*`, rejects blank or duplicate IDs, and does not normalize malformed values. Categories have no fixed allow-list. It also rejects absolute paths, path traversal, and paths outside the required media prefixes. An image path must be under `assets/images/` and end in `.png`; noun- and answer-audio paths must be under `assets/audio/` and end in `.mp3`. It deliberately does not check whether a permitted path exists; TASK-02-0004 applies those rules to the complete approved snapshot and verifies that every declared media asset can be loaded. Validation fails fast with a `FormatException`; it does not aggregate issues or return a partial collection.

## Next task

TASK-02-0004: validate the complete approved content snapshot.
