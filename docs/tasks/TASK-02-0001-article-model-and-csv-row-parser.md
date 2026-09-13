---
id: TASK-02-0001
title: Define the article model and map valid JSON records
status: ready
milestone: content_model_and_validation
depends_on: [TASK-01-0004]
blocks: [TASK-02-0002, TASK-02-0003]
updated: 2026-09-13
---

## Scope

Define the typed `Article` domain model and a pure JSON-record mapper that transforms a valid `assets/articles.json` record into that model. Keep mapping independent of Flutter widget code and asset-bundle I/O.

## Completion criteria

- `Article` represents the JSON properties needed by the first release: ID, article, noun, image path, noun-audio path, and answer-audio path.
- A pure mapper transforms a well-formed JSON record into an `Article`.
- Unit tests cover representative valid `der`, `die`, and `das` records.
- No widget, asset-bundle loading, full-dataset validation, or answer-exercise behavior is added.

## Evidence

Not started.

## Decisions and blockers

JSON record mapping must remain separately testable. Semantic validation and duplicate-ID detection belong to TASK-02-0003; loading the bundled file belongs to TASK-02-0002.

## Next task

TASK-02-0002: load the bundled JSON through a repository.
