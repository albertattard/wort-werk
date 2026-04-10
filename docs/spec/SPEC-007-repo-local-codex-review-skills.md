---
id: SPEC-007
title: Repo-Local Codex Review Skills
status: in_progress
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

- [ ] Repository contains three repo-local skills under `.codex/skills/`:
  - `architecture-review`
  - `project-coherence-review`
  - `security-analysis`
- [ ] Each skill defines when it should be used and which repo artifacts must be read first.
- [ ] Each skill uses a distinct review lens and output structure.
- [ ] Skill docs explicitly state that specs, tasks, and ADRs remain the source of truth.
- [ ] Specification and task indexes reference this spec and its implementation task.
