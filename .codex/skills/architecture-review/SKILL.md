---
name: architecture-review
description: Use when reviewing Wort-Werk design proposals, implementation plans, ADR changes, repository-level direction, or refactors that affect boundaries, layering, or long-term structure.
---

# Architecture Review

Use this skill for design and planning review before implementation, or when judging whether a larger change fits the current repository direction.

Do not use this skill for a narrow code review of an isolated diff when the main question is consistency with surrounding code. Use `project-coherence-review` for that.

## Read First

Before judging the change, read:

1. `AGENTS.md`
2. the relevant files in `docs/spec/`
3. the linked task files in `docs/tasks/`
4. the relevant ADRs in `docs/decisions/`

If those artifacts are missing or inconsistent, stop and call that out before commenting on implementation details.

## Repository Context

- Java 25
- Spring Boot
- Thymeleaf server-rendered web application with HTMX
- Passkey-first authentication direction
- PostgreSQL
- OCI container deployment
- Spec-first, task-first workflow with ADR-backed decisions

## Review Goals

Check whether the proposal or change:

- fits the current system direction,
- respects existing specs and ADRs,
- keeps responsibilities separated cleanly,
- avoids parallel abstractions for the same concern,
- avoids short-term convenience that creates long-term structural debt.

Prefer consistency with the current repository unless there is a clear and defensible reason to change direction.

## Review Lens

Be strict about:

- violating spec or ADR intent,
- introducing duplicate architectural seams,
- mixing concerns across layers,
- letting design decisions leak into implementation without documentation,
- adding one-off exceptions that will become permanent structure.

## Output Format

- Decision: approve / approve with changes / needs redesign
- Fit: how well it matches the repository direction and ADRs
- Risks: architectural risks and long-term consequences
- Alternatives: better structures or boundaries, if any
- Next steps: concrete actions required before or during implementation

## Source Of Truth

Specs, tasks, and ADRs remain the source of truth. This skill is a review lens, not a replacement for repository documentation.
