# Tasks

File-based task tracker for Wort-Werk.

## Workflow

1. Create or update a `SPEC` in `docs/spec/`.
2. Create a `TASK` linked to the spec in `docs/tasks/`.
3. Verify baseline: run tests and ensure they pass before making changes.
4. Apply TDD for functional behavior:
   - create or update a functional test first,
   - run functional tests and confirm the new test fails,
   - implement the change,
   - run tests again and confirm it passes.
5. Run `./mvnw clean verify` before committing.
6. Move task status to `done` after acceptance criteria pass.

## Task Metadata

New task files must include these front matter fields:
- `id`
- `title`
- `status`
- `category`
- `related_features`
- `owner`
- `created`
- `updated`

## Task Categories

Use one of these `category` values for new tasks:
- `quiz`
- `content`
- `agentic`
- `infrastructure`
- `repo-process`

## Task Files

- [TASK-001: Implement SPEC-001 Quiz Vertical Slice](./quiz/TASK-001-implement-spec-001-quiz-vertical-slice.md)
- [TASK-002: Enforce Correct Selection Before Advancing and Show Noun](./quiz/TASK-002-enforce-correct-before-advance-and-show-noun.md)
- [TASK-003: Center Noun and Article Buttons](./quiz/TASK-003-center-noun-and-article-buttons.md)
- [TASK-004: Use UI Clicks in Functional Tests](./quiz/TASK-004-use-ui-clicks-in-functional-tests.md)
- [TASK-005: Add Audio Cues for Prompt and Correct Answer](./quiz/TASK-005-add-audio-cues-for-prompt-and-correct-answer.md)

## Pending

- (none)

## In Progress

- (none)

## Done

- [x] [TASK-001: Implement SPEC-001 Quiz Vertical Slice](./quiz/TASK-001-implement-spec-001-quiz-vertical-slice.md)
- [x] [TASK-002: Enforce Correct Selection Before Advancing and Show Noun](./quiz/TASK-002-enforce-correct-before-advance-and-show-noun.md)
- [x] [TASK-003: Center Noun and Article Buttons](./quiz/TASK-003-center-noun-and-article-buttons.md)
- [x] [TASK-004: Use UI Clicks in Functional Tests](./quiz/TASK-004-use-ui-clicks-in-functional-tests.md)
- [x] [TASK-005: Add Audio Cues for Prompt and Correct Answer](./quiz/TASK-005-add-audio-cues-for-prompt-and-correct-answer.md)

## Blocked

- (none)
