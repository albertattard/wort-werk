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

Define and implement deterministic content validation for loaded article records. Validate IDs, supported article values, required fields, and declared local asset paths without adding UI behavior or a separate pre-Flutter validation tool.

## Completion criteria

- Duplicate or missing IDs are rejected.
- Only `der`, `die`, and `das` are accepted as articles.
- Missing required fields and invalid declared image, noun-audio, or answer-audio paths are rejected.
- The repository exposes validation failures predictably for callers and tests.
- Unit tests cover each invalid-content category and a valid collection.

## Evidence

Blocked by TASK-02-0001 and TASK-02-0002.

## Decisions and blockers

This task defines semantic content-policy failures. TASK-02-0004 applies those rules to the complete approved snapshot and verifies that every declared media asset can be loaded.

## Next task

TASK-02-0004: validate the complete approved content snapshot.
