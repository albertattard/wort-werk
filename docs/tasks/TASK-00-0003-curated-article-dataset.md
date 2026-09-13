---
id: TASK-00-0003
title: Full approved article dataset
status: complete
milestone: content_intake
depends_on: [TASK-00-0002]
blocks: [TASK-02-0004]
updated: 2026-09-13
---

## Scope

Use the complete locally bundled set of approved article records, with their required images and noun/answer audio. Exclude sentence content from the article-practice release.

## Completion criteria

- The full article dataset represents `der`, `die`, and `das`.
- Every CSV row has exactly one locally present image, noun-audio file, and answer-audio file.
- All retained media is authorized by TASK-00-0002.
- CSV asset paths remain unchanged for all article records.

## Evidence

The project owner chose the full approved article dataset rather than an arbitrary 10-to-20-item subset. `assets/articles.csv` retains all 127 rows: 57 `der`, 43 `die`, and 27 `das` records. This exceeds the ten-question session requirement while retaining a broader, balanced learning set.

TASK-00-0001 established that every row resolves to its declared local image, noun-audio, and answer-audio files. CSV paths remain unchanged.

## Decisions and blockers

All retained article media is approved by TASK-00-0002. Repeatable validation for
this full snapshot is deferred to milestone 2 alongside the content loader.
