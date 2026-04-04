---
id: SPEC-001
title: German Article Quiz MVP
status: in_progress
priority: high
owner: @aattard
last_updated: 2026-04-04
---

## Problem

Learners need a focused way to practice German noun articles from visual prompts without relying on translation.

## User-facing Behavior

The app provides a quiz session where each round shows one image and three article options:
- `der`
- `die`
- `das`

The noun is shown under the image.

If the learner selects a wrong article, the same object remains visible, feedback is shown, and the correct article is highlighted.

Only after the learner selects the correct article does the quiz advance to the next entry.

The noun label and article choices are visually centered under the image.

When an image is shown, the app plays the noun audio once (without article).

The noun row includes a speaker icon button that replays noun-only audio on demand.

When the learner selects the correct article, the app plays the full phrase audio (article + noun) to reinforce association.

The quiz advances to the next entry only after the full article+noun audio playback completes.

At the end of 10 rounds, the app displays the final score.

## Inputs/Outputs

Input:
- click/tap one article option for the current image
- click/tap speaker icon next to noun to replay noun-only audio

Output:
- immediate feedback when the selected article is wrong
- correct article highlight on wrong selections
- same object shown until correct answer is chosen
- noun audio when a prompt is shown
- noun-only audio replay when speaker icon is pressed
- article+noun audio when the correct article is selected
- final score after 10 rounds

## Acceptance Criteria

- [x] The quiz presents exactly one image per round.
- [x] The noun for the current object is shown under the image.
- [x] The noun label and article choices are centered for easier focus.
- [x] The learner can answer only with `der`, `die`, or `das`.
- [x] A wrong selection keeps the same object visible and highlights the correct article.
- [x] The quiz advances only after a correct selection.
- [x] When a prompt is shown, noun-only audio is played once.
- [x] A speaker icon is shown next to the noun and replays noun-only audio when pressed.
- [x] When a correct article is selected, article+noun audio is played once before moving on.
- [x] The next prompt is shown only after correct article+noun audio playback completes.
- [x] Learner-facing text never includes English translations.
- [x] A session consists of exactly 10 rounds.
- [x] A final score is shown at the end of the session.
- [x] Question and audio path data are loaded from `assets/articles.csv`.
- [x] Functional tests validate article selection via real button clicks.
- [x] Nouns with umlauts use ASCII-safe image/audio asset paths to avoid Unicode path normalization issues.
- [x] Every image in `assets/images` has a corresponding entry in `assets/articles.csv`.

## Non-goals

- Adaptive scheduling or spaced repetition in this spec.
- User account management.
- Case drills beyond nominative article selection.
