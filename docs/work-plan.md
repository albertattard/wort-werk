# Work plan

This document is the execution and handoff source of truth for the first release. `docs/first-release.md` defines the product boundary; this plan defines milestone order and completion evidence. Individual task state, dependencies, evidence, and blockers are recorded in [`docs/tasks/`](tasks/).

## Working rules

- Work only on the current milestone unless its documented dependency requires otherwise.
- Preserve the first-release scope. Do not add a backend, accounts, synchronization, sentence exercises, or a generalized spaced-repetition engine.
- Do not download learning assets at runtime. Approved resources must be copied into this repository as a locally bundled snapshot.
- Keep commits focused on one completed concern. Do not stage unrelated work.
- At the end of each working session, update the affected task file in [`docs/tasks/`](tasks/) with its status, evidence, and next task. Update this plan only when milestone-level evidence or sequencing changes.

## Current state

- First-release scope is documented in `docs/first-release.md`.
- Flutter 3.47.4 and the Android SDK toolchain are installed and configured for the selected USB-connected Google Pixel 8; `flutter doctor -v` reports a healthy Android toolchain and `flutter devices` detects the authorized phone.
- The Android-only Flutter baseline is generated, declares the approved bundled article assets, and passes `flutter pub get` and `flutter analyze`.
- The full `assets/` article snapshot is committed. TASK-00-0001 verified that all 127 rows in `assets/articles.csv` resolve to their declared local image and audio files.
- The full snapshot is approved for redistribution by the project owner; TASK-00-0002 records the authorization for all imported images and audio.
- The article snapshot is ready for application development. Repeatable content validation is scheduled in milestone 2 alongside the content loader.
- Repository hygiene for a Flutter application is committed.

## Milestones

### 0. Content intake

**Status:** complete

**Outcome:** A complete, approved, locally bundled article-practice content set is ready for app development.

**Scope:**

1. Inventory the candidate `assets/` snapshot and verify its CSV-to-media mappings (complete: TASK-00-0001).
2. Record the owner authorization to bundle and redistribute the imported assets in `docs/first-release.md` (complete: TASK-00-0002).
3. Retain all 127 approved article records from `articles.csv` and the media they declare, preserving their CSV asset paths.
4. Do not add sentence content or unrelated media to the release snapshot.

**Not in scope:** Creating a Flutter project, designing screens, or importing sentence content.

**Completion evidence:**

- The full 127-item snapshot and asset-authorization decision are documented.
- Every image and audio path for every article record resolves locally.
- Asset provenance and redistribution permission are explicitly recorded.
- TASK-00-0001's recorded integrity check confirms the current CSV structure, IDs, supported articles, and all declared local media paths.

**Commit boundary:** Content snapshot and provenance documentation, separate from Flutter scaffolding.

**Next task:** Complete TASK-01-0001 to select the first physical target device, then begin milestone 1.

### 1. Flutter baseline and physical-device launch

**Status:** complete

**Outcome:** A generated Flutter application launches on one physical target device.

**Scope:**

1. The initial physical target is Android on a Google Pixel 8, connected by USB (TASK-01-0001 complete).
2. Install Flutter and platform tooling, then resolve `flutter doctor` findings relevant to that target.
3. Generate the Flutter application in this repository without replacing existing content.
4. Declare the bundled asset directories in `pubspec.yaml`.
5. Launch the generated app, with its configured Android application ID, on the physical device.

**Completion evidence:**

- Relevant `flutter doctor` checks pass.
- `flutter devices` detects the target phone.
- The generated app launches from the physical device's home screen.

**Commit boundary:** Flutter project scaffolding and platform configuration only.

**Task sequence:** TASK-01-0001 (target selection) → TASK-01-0002 (toolchain) → TASK-01-0003 (scaffolding and assets) → TASK-01-0004 (physical-device launch).

**Completion evidence:** On 2026-09-13, the generated baseline with its configured Android application ID built, installed, and launched on the USB-connected Google Pixel 8 (`41290DLJH001LG`). After returning the phone to its home screen, the app was manually reopened from its launcher icon. Android also successfully reopened `io.github.albertattard.wortwerk.MainActivity`. TASK-01-0004 records the commands and observed results.

**Next task:** Define the first milestone-2 task record for the article domain model and bundled CSV repository.

### 2. Content model and validation

**Status:** ready

**Outcome:** The app loads selected article records into typed models and rejects invalid content predictably.

**Scope:**

1. Add an `Article` domain model and CSV content repository.
2. Parse the bundled CSV without performing file or UI work inside widgets.
3. Implement content validation for IDs, articles, and declared asset paths.
4. Add unit tests for valid and invalid rows.

**Completion evidence:**

- Unit tests cover parsing and invalid-content failures.
- The full approved bundled dataset loads successfully and passes repeatable validation.

**Commit boundary:** One focused commit for each completed task.

**Task sequence:** TASK-02-0001 (model and row parser) → TASK-02-0002 (bundled repository) → TASK-02-0003 (invalid-content handling) → TASK-02-0004 (full snapshot validation).

**Next task:** Complete TASK-02-0001 to define the article model and parse valid CSV rows.

### 3. Article-practice exercise

**Status:** blocked by milestone 2

**Outcome:** A learner can answer an article question by tapping an article button and receive clear feedback.

**Scope:**

1. Display one selected article record with its image above its noun text.
2. Provide explicit noun-audio playback.
3. Present three large, tappable answer buttons labelled `der`, `die`, and `das` beneath the question.
4. Submit the answer when the learner taps a button; do not provide typed-answer input or require the keyboard.
5. Show correct or incorrect feedback, the complete answer, and answer-audio playback.
6. Continue to the next item after feedback.

**Completion evidence:**

- Widget tests cover correct and incorrect button selections and verify that no typed-answer input is present.
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
