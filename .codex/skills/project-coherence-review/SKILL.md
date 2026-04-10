---
name: project-coherence-review
description: Use when reviewing Wort-Werk code, diffs, or implementation details for consistency across modules, naming, layering, testing patterns, and repository conventions.
---

# Project Coherence Review

Use this skill for reviewing code, uncommitted changes, or completed implementations where the main question is whether the change stays coherent with the rest of Wort-Werk.

Do not use this skill as the primary lens for repo-direction or ADR-level design questions. Use `architecture-review` when the change affects system direction, layering strategy, or long-term design.

## Read First

Before reviewing the change, read:

1. `AGENTS.md`
2. the relevant spec in `docs/spec/`
3. the linked task in `docs/tasks/`
4. any ADRs that define the pattern being touched
5. the surrounding production and test code for the changed area

If the spec/task/ADR trail does not support the implementation, call that out explicitly.

## Repository Context

- Java 25
- Spring Boot
- Thymeleaf + HTMX
- PostgreSQL-backed verification
- Playwright e2e coverage
- Specification-first workflow with TDD and `./mvnw clean verify` as the commit gate

## Review Goals

Check whether the change:

- uses the same patterns as nearby code,
- preserves naming and module boundaries,
- keeps tests aligned with repository conventions,
- solves the local problem without creating a second competing approach,
- leaves the codebase easier to understand rather than more fragmented.

Prefer one coherent project-wide approach over locally convenient exceptions.

## Review Lens

Be especially alert for:

- one-off implementations that bypass existing patterns,
- drift between controller/service/repository/test structure,
- inconsistent naming or state flow,
- duplicated behavior hidden behind slightly different abstractions,
- missing tests for behavior that the rest of the project treats as standard.

## Output Format

- Overall verdict
- Coherence notes
- Inconsistencies
- Better organization options
- Concrete recommendations

## Source Of Truth

Specs, tasks, and ADRs remain the source of truth. This skill helps judge coherence against them and against the current codebase.
