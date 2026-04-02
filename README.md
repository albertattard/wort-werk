# Wort-Werk

Wort-Werk is a Java-based German article trainer built with a specification-first workflow.

## Source of Truth

The product specification in `docs/spec/` is the authoritative source for behavior and requirements.
Code is an implementation of those specs.

## Working Model

1. Define or update the specification first.
2. Create a linked task in `docs/tasks/`.
3. Implement code that satisfies the spec/task acceptance criteria.
4. Update task/spec status only after acceptance criteria pass.

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
