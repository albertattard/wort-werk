# Wort-Werk

Wort-Werk is a Java-based German article trainer built with a specification-first workflow.

## Source of Truth

The product specification in `docs/spec/` is the authoritative source for behavior and requirements.
Code is an implementation of those specs.

## Working Model

1. Define or update the specification first.
2. Create a linked task in `docs/tasks/`.
3. Verify a clean baseline before changes: all tests must pass.
4. Use TDD for behavior changes:
   - add or update a functional test first,
   - run functional tests and confirm the new test fails,
   - implement the change,
   - re-run tests and confirm the new test passes.
5. Update task/spec status only after acceptance criteria pass.

## Documentation Structure

```text
docs/
  spec/
    Product-Vision.md
    SPEC-001-*.md
  decisions/
    ADR-0001-*.md
  tasks/
    TASK-001-*.md
```

## Testing Conventions

- Use AssertJ as the default assertion library for all tests.
- Use `./mvnw test` for unit/integration tests (excluding `@Tag("e2e")`).
- Use `./mvnw verify` to run the full pipeline, including `@Tag("e2e")` tests.
- Use `./mvnw clean verify` as the required pre-commit validation command.
