# Tasks

File-based task tracker for Wort-Werk.

## Workflow

1. Create or update a `SPEC` in `docs/spec/`.
2. Create a `TASK` linked to the spec in `docs/tasks/`.
3. Implement the task in code.
4. Move task status to `done` after acceptance criteria pass.

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

## Pending

- (none)

## In Progress

- (none)

## Done

- [x] [TASK-001: Implement SPEC-001 Quiz Vertical Slice](./quiz/TASK-001-implement-spec-001-quiz-vertical-slice.md)

## Blocked

- (none)
