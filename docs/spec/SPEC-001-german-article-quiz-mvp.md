---
id: SPEC-001
title: German Article Quiz MVP
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-02
---

## Problem

Learners need a focused way to practice German noun articles from visual prompts without relying on translation.

## User-facing Behavior

The app provides a quiz session where each round shows one image and three article options:
- `der`
- `die`
- `das`

After each answer, the app immediately shows whether the answer is correct and displays the correct German phrase (for example: `Richtig: der Apfel`).

At the end of 10 rounds, the app displays the final score.

## Inputs/Outputs

Input:
- click/tap one article option for the current image

Output:
- immediate feedback per round (`Richtig`/`Falsch`)
- correct article+noun in German
- final score after 10 rounds

## Acceptance Criteria

- [x] The quiz presents exactly one image per round.
- [x] The learner can answer only with `der`, `die`, or `das`.
- [x] Feedback is immediate after each answer.
- [x] Learner-facing text never includes English translations.
- [x] A session consists of exactly 10 rounds.
- [x] A final score is shown at the end of the session.
- [x] Question data is loaded from `assets/articles.csv`.

## Non-goals

- Adaptive scheduling or spaced repetition in this spec.
- User account management.
- Case drills beyond nominative article selection.
