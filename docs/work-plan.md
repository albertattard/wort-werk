# Work plan

This document is the execution and handoff source of truth for the first release. `docs/first-release.md` defines the product boundary; this plan defines milestone order and completion evidence. Individual task state, dependencies, evidence, and blockers are recorded in [`docs/tasks/`](tasks/).

## Working rules

- Work only on the current milestone unless its documented dependency requires otherwise.
- Preserve the first-release scope. Do not add a backend, accounts, synchronization, sentence exercises, or a generalized spaced-repetition engine.
- Do not download learning assets at runtime. Approved resources must be copied into this repository from a pinned source revision.
- Keep commits focused on one completed concern. Do not stage unrelated work.
- At the end of each working session, update the affected task file in [`docs/tasks/`](tasks/) with its status, evidence, and next task. Update this plan only when milestone-level evidence or sequencing changes.

## Current state

- First-release scope is documented in `docs/first-release.md`.
- Flutter application setup has not started.
- The candidate `assets/` snapshot is committed. Task 0.1 verified that all 127 rows in `assets/articles.csv` resolve to their declared local image and audio files.
- The candidate snapshot is not yet approved for redistribution; task 0.2 must record the pinned source revision and explicit authorization before any records or media are selected for the first release.
- Repository hygiene for a Flutter application is committed.

## Milestones

### 0. Content intake

**Status:** in progress (task 0.2 blocked on provenance and redistribution authorization)

**Outcome:** A small, approved, locally bundled article-practice content set is ready for app development.

**Scope:**

1. Inventory the candidate `assets/` snapshot and verify its CSV-to-media mappings (complete: task 0.1).
2. Record the exact source commit and the redistribution/provenance decision in `docs/first-release.md`.
3. Select an initial subset of 10 to 20 approved article records from `articles.csv`.
4. Retain only the approved assets required by the selected records, preserving their CSV asset paths.
5. Add a repeatable validation approach that checks unique IDs, supported articles, and asset-path existence.

**Not in scope:** Creating a Flutter project, designing screens, or importing sentence content.

**Completion evidence:**

- The selected item IDs and source commit are documented.
- Every image and audio path for the selected records resolves locally.
- Asset provenance and redistribution permission are explicitly recorded.
- The content-validation check passes.

**Commit boundary:** Content snapshot and provenance documentation, separate from Flutter scaffolding.

**Next task:** Complete task 0.2: record the pinned upstream source revision and explicit redistribution authorization for images and audio.

### 1. Flutter baseline and physical-device launch

**Status:** blocked by milestone 0 and target-device selection

**Outcome:** A generated Flutter application launches on one physical target device.

**Scope:**

1. Decide the initial physical target: iOS, Android, or both.
2. Install Flutter and platform tooling, then resolve `flutter doctor` findings relevant to that target.
3. Generate the Flutter application in this repository without replacing existing content.
4. Declare the bundled asset directories in `pubspec.yaml`.
5. Launch the unmodified app on the physical device.

**Completion evidence:**

- Relevant `flutter doctor` checks pass.
- `flutter devices` detects the target phone.
- The generated app launches from the physical device's home screen.

**Commit boundary:** Flutter project scaffolding and platform configuration only.

**Next task:** Add content-model parsing after the baseline is committed.

### 2. Content model and validation

**Status:** blocked by milestone 1

**Outcome:** The app loads selected article records into typed models and rejects invalid content predictably.

**Scope:**

1. Add an `Article` domain model and CSV content repository.
2. Parse the bundled CSV without performing file or UI work inside widgets.
3. Implement content validation for IDs, articles, and declared asset paths.
4. Add unit tests for valid and invalid rows.

**Completion evidence:**

- Unit tests cover parsing and invalid-content failures.
- The selected article subset loads successfully from bundled assets.

**Commit boundary:** Content model, loader, validator, and tests.

**Next task:** Build the article-practice interaction using the validated content model.

### 3. Article-practice exercise

**Status:** blocked by milestone 2

**Outcome:** A learner can answer an article question and receive clear feedback.

**Scope:**

1. Select and display an article record with its image and noun.
2. Provide explicit noun-audio playback.
3. Present `der`, `die`, and `das` choices.
4. Show correct or incorrect feedback, the complete answer, and answer-audio playback.
5. Continue to the next item after feedback.

**Completion evidence:**

- Widget tests cover correct and incorrect answers.
- A manual phone test confirms image rendering and both audio actions.

**Commit boundary:** Article-practice feature and its tests.

**Next task:** Persist results and make missed items reviewable.

### 4. Local progress and review

**Status:** blocked by milestone 3

**Outcome:** Completed and missed items persist locally, and missed items can be practiced again.

**Scope:**

1. Persist completed and missed IDs locally on the device.
2. Add new/random and missed-item review session modes.
3. Define empty-review behavior clearly.

**Completion evidence:**

- Closing and reopening the app preserves a recorded missed item.
- The item appears in a review session.
- Tests cover progress persistence and empty-review behavior.

**Commit boundary:** Local progress feature and tests.

**Next task:** Run the end-to-end acceptance check on a physical phone.

### 5. First-release acceptance

**Status:** blocked by milestone 4

**Outcome:** The first release meets the documented acceptance criteria on a physical device.

**Scope:**

1. Run a 10-question offline practice session.
2. Verify image, noun audio, answer audio, feedback, relaunch persistence, and review mode.
3. Run the automated test suite and static analysis.
4. Record any remaining defects as explicit follow-up work rather than expanding this release.

**Completion evidence:**

- Every acceptance criterion in `docs/first-release.md` is marked as verified or explicitly deferred.
- Automated tests and static analysis pass.
- Physical-device test results are recorded here.

**Commit boundary:** Acceptance-report documentation or narrowly scoped fixes only.

## New-session handoff prompt

Use this prompt to resume work in a new session:

> Read `README.md`, `docs/first-release.md`, and `docs/work-plan.md`. Inspect `git status --short`. Continue only the current milestone, respect its scope and exclusions, run its listed completion checks, update `docs/work-plan.md` with evidence and the next task, and make a focused commit only when the completed change is ready.
