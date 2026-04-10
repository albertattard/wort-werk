---
id: SPEC-007
title: Repo-Local Codex Review Skills
status: done
priority: medium
owner: @aattard
last_updated: 2026-04-10
---

## Problem

Wort-Werk now has enough repository-specific process and architecture context that generic agent behavior is no longer sufficient for every review task. Without repo-local skills, architecture, coherence, and security reviews risk becoming inconsistent across threads and may miss required repo artifacts such as specs, tasks, ADRs, and `AGENTS.md`.

## Goal

Define a repo-owned skill set that gives Codex consistent review lenses for Wort-Werk while preserving the existing spec-first, task-first workflow.

## Required Skills

The first slice must define three review skills:

1. `architecture-review`
   - Use for design proposals, implementation plans, ADR alignment, and repository-level direction.
2. `project-coherence-review`
   - Use for code or change reviews that focus on consistency across modules, naming, layering, and project patterns.
3. `security-analysis`
   - Use for authentication, session, database, container, deployment, and secret-handling reviews.

## Required Repository Behavior

- Skills must live inside the repository so they version with the project.
- Skills must be scoped to Wort-Werk and instruct Codex to read:
  - `AGENTS.md`
  - relevant files in `docs/spec/`
  - relevant files in `docs/tasks/`
  - relevant files in `docs/decisions/`
- Skills must complement, not replace, the mandatory spec/task/ADR workflow.
- Skill boundaries must be explicit enough to avoid overlap between architecture and project-coherence reviews.
- The initial slice may defer optional UI metadata such as `agents/openai.yaml`.
- Skill usage must be documented as explicit workflow checkpoints rather than assumed tribal knowledge.
- Skill usage must remain conditional; not every small change should require all skills.

## Workflow Checkpoints

Use the review skills at these points in the workflow:

1. `architecture-review`
   - use before implementation for design-heavy work,
   - especially for design proposals, ADR-impacting changes, refactors, and repository-direction questions.
2. `project-coherence-review`
   - use before commit for non-trivial code changes where consistency with repository patterns matters.
3. `security-analysis`
   - use for authentication, session, CSRF, database, container, deployment, secret, and OCI-related changes.

Small, local, low-risk changes do not need all three skills by default.

## Storage and Naming

- Store repo-local skills under `.codex/skills/`.
- Use one folder per skill with a required `SKILL.md`.
- Prefer stable, explicit names that can be invoked directly in prompts.

## Out of Scope

- Adding implementation or code-generation skills.
- Replacing repository docs with skill content.
- Auto-invoking skills outside Codex-supported environments.
- Defining organization-wide skills outside this repository.

## Acceptance Criteria

- [x] Repository contains three repo-local skills under `.codex/skills/`:
  - `architecture-review`
  - `project-coherence-review`
  - `security-analysis`
- [x] Each skill defines when it should be used and which repo artifacts must be read first.
- [x] Each skill uses a distinct review lens and output structure.
- [x] Skill docs explicitly state that specs, tasks, and ADRs remain the source of truth.
- [x] Specification and task indexes reference this spec and its implementation task.
- [x] Repository workflow docs explain when to use the skills.
- [x] Skill usage remains conditional rather than mandatory on every task.
