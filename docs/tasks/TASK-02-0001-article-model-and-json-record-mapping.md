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

Define typed `Article` and immutable `JsonArticleRecord` models, a `GermanArticle` enum, and a pure mapper that transforms a valid `assets/articles.json` record into an `Article`. Keep mapping independent of Flutter widget code and asset-bundle I/O.

## Completion criteria

- `Article` represents the JSON properties needed by the first release: ID, article, noun, category, image path, noun-audio path, and answer-audio path.
- `Article.article` is a `GermanArticle` enum with exactly `der`, `die`, and `das` values.
- `JsonArticleRecord` uses the lower-camel-case JSON properties: `id`, `noun`, `article`, `category`, `imagePath`, `nounAudioPath`, and `answerAudioPath`.
- JSON-record decoding rejects a missing or non-string required property with a `FormatException` that identifies the property, a one-based record index, and the ID when available.
- JSON-record decoding rejects an unknown property with a `FormatException`.
- A pure mapper transforms a well-formed `JsonArticleRecord` into an `Article`.
- The mapper rejects an unsupported article value with a `FormatException`.
- Unit tests cover representative valid `der`, `die`, and `das` records, plus an unsupported article value.
- No widget, asset-bundle loading, full-dataset validation, or answer-exercise behavior is added.

## Evidence

Not started.

## Decisions and blockers

JSON record mapping must remain separately testable. It owns structural-schema failures and translation of the raw article string to `GermanArticle`, including rejection of unsupported values. Collection-level validation and duplicate-ID detection belong to TASK-02-0003; loading the bundled file belongs to TASK-02-0002.

## Next task

TASK-02-0002: load the bundled JSON through a repository.
