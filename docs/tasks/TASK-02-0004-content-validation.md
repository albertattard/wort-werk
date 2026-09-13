---
id: TASK-02-0004
title: Validate the complete approved content snapshot
status: blocked
milestone: content_model_and_validation
depends_on: [TASK-02-0002, TASK-02-0003]
blocks: []
updated: 2026-09-13
---

## Scope

Apply the repository and validation rules to the complete curated `assets/articles.json` snapshot and its declared bundled media. Do not create a standalone pre-Flutter validation tool.

## Completion criteria

- A repeatable check loads all 127 curated JSON records through the repository and validation path.
- Every image, noun-audio, and answer-audio reference declared by those records resolves from the bundled assets.
- The check passes for the complete approved snapshot.
- The command and its expected result are documented.

## Evidence

Blocked by TASK-02-0002 and TASK-02-0003. TASK-00-0001 established the current snapshot's integrity; this task adds repeatable validation beside the app's JSON loader and unit tests.

## Decisions and blockers

The milestone-2 implementation must remain offline. TASK-02-0003 owns the invalid-content test cases; this task verifies the complete approved snapshot and does not introduce exercise UI.

## Next task

Milestone 2 is complete when this task's evidence is recorded. Then define the first Milestone 3 article-practice task.
