---
id: TASK-005
title: Add Audio Cues for Prompt and Correct Answer
status: done
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-02
updated: 2026-04-02
---

## Summary

Add audio playback to reinforce image-word association: play noun-only audio when the prompt appears, add a replay control beside the noun, and play article+noun audio when the learner selects the correct article.

## Scope

- On each round prompt, play `assets/audio/<Noun>.mp3` once.
- Show a speaker icon button beside the noun label.
- On speaker icon click/tap, replay `assets/audio/<Noun>.mp3`.
- On correct selection, play `assets/audio/<article> <Noun>.mp3` once.
- Advance to next prompt only after correct article+noun audio playback completes.
- Keep current wrong-answer behavior unchanged.
- Integrate playback with current round progression logic.

## Assumptions

- Audio files generated under `assets/audio` are the source of truth.
- Missing audio files should not crash the round; fallback behavior should be defined in implementation.
- Next round must start only after the correct-answer audio finishes.

## Acceptance Criteria

- [x] Prompt loads and noun-only audio is played once.
- [x] Speaker icon is visible next to noun and replays noun-only audio.
- [x] Correct selection plays article+noun audio once.
- [x] Next prompt does not render until correct article+noun audio playback has completed.
- [x] Quiz proceeds correctly through rounds with audio enabled.
- [x] Functional tests cover prompt audio trigger, replay trigger, and correct-answer audio trigger.
- [x] `./mvnw clean verify` passes.

## Notes

- Wrong selections remain silent; only visual feedback is shown.
- Replay is disabled while correct-answer audio is playing.
- Audio paths are read from `assets/articles.csv` when provided, with naming-convention fallback for compatibility.
