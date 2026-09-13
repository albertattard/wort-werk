---
id: TASK-02-0004
title: Content validation
status: deferred
milestone: content_model_and_validation
depends_on: []
blocks: []
updated: 2026-09-13
---

## Scope

Add a repeatable validation check for the curated `assets/articles.csv` and its referenced local media as part of milestone 2's content-model work. Do not create a standalone pre-Flutter validation tool.

## Completion criteria

- The check rejects duplicate IDs.
- The check rejects articles other than `der`, `die`, and `das`.
- The check rejects missing image, noun-audio, and answer-audio paths.
- The check passes for the curated bundled dataset.
- The command and its expected result are documented.

## Evidence

Deferred by the project owner on 2026-09-13. TASK-00-0001 already established the current snapshot's integrity; repeatable validation belongs with the app's CSV loader and its unit tests in milestone 2.

## Decisions and blockers

The milestone-2 implementation must remain offline and must test duplicate IDs, unsupported articles, and missing declared asset paths.
