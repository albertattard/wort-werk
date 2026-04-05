# AGENTS.md

This file defines the default working agreement for all coding threads in this repository.

## Purpose

Build and maintain Wort-Werk using a specification-first, test-driven workflow with consistent quality gates.

## Source of Truth

- Product behavior: `docs/spec/`
- Task tracking: `docs/tasks/`
- Technical decisions (ADRs): `docs/decisions/`

If there is a conflict, update specs/ADRs first and then implement.

## Required Workflow

The following gates are mandatory and sequential:

1. Create or update a `SPEC` in `docs/spec/`.
2. Create or update a linked `TASK` in `docs/tasks/`.
3. Confirm both files exist and are linked before touching production code or tests.
4. Verify baseline before changes: tests must pass.
5. Apply TDD for functional behavior changes:
   - create or update a functional test first,
   - run functional tests and confirm the new test fails,
   - implement the change,
   - run tests and confirm the new test passes.
6. Mark task/spec status only after acceptance criteria pass.

If a request arrives without a spec/task update, stop implementation and create/update those artifacts first.

## Testing Standards

- Assertion framework: **AssertJ** (`org.assertj.core.api.Assertions.assertThat`).
- Unit/integration tests (excluding e2e):
  - `./mvnw test`
- Full pipeline including e2e:
  - `./mvnw clean verify`
- E2E tests:
  - must be tagged with `@Tag("e2e")`
  - run only in integration-test/verify phase (Failsafe)

## Commit Gate

Before committing, run:

```bash
./mvnw clean verify
```

A commit should not be created unless this passes.

## Current Stack

- Java 25
- Spring Boot
- Thymeleaf + HTMX
- Playwright for Java (e2e)

## Product Constraints

- Learner-facing experience is German-first for article training.
- Image-based prompt flow for noun article guessing (`der`, `die`, `das`).
- Avoid introducing English learner-facing prompts unless explicitly requested by the user.

## Documentation Hygiene

When changing workflow or engineering standards:

1. Add/update an ADR in `docs/decisions/`.
2. Update indexes/readmes (`docs/decisions/README.md`, `README.md`, `docs/tasks/README.md`) as needed.
3. Keep examples and commands aligned with current tooling.

## Trigger Phrases

- `update assets`
  - Run `./tools/update-assets`
  - Then run `./mvnw clean verify`
  - If `tools/update-assets` reports missing metadata, add the missing rows directly to `assets/articles.csv` and re-run
  - Place new source images in `assets/images/new`; the sync moves them to `assets/images/original` after success
