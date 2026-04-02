---
id: TASK-005
title: Add Audio Cues for Prompt and Correct Answer
status: pending
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

- [ ] Prompt loads and noun-only audio is played once.
- [ ] Speaker icon is visible next to noun and replays noun-only audio.
- [ ] Correct selection plays article+noun audio once.
- [ ] Next prompt does not render until correct article+noun audio playback has completed.
- [ ] Quiz proceeds correctly through rounds with audio enabled.
- [ ] Functional tests cover prompt audio trigger, replay trigger, and correct-answer audio trigger.
- [ ] `./mvnw clean verify` passes.

## Open Questions

- Should wrong selections also play audio (for example, the correct phrase), or remain silent?
- Should replay be disabled while other audio is currently playing, or should replay interrupt and restart noun audio?
