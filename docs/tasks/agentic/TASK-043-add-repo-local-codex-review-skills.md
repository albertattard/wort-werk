---
id: TASK-043
title: Add Repo-Local Codex Review Skills
status: done
category: agentic
related_features:
  - SPEC-007
owner: @aattard
created: 2026-04-10
updated: 2026-04-10
---

## Summary

Add three repo-local Codex review skills for Wort-Werk so architecture, project-coherence, and security reviews follow repository-specific guidance instead of relying on generic prompting.

## Scope

- Create `.codex/skills/architecture-review/SKILL.md`.
- Create `.codex/skills/project-coherence-review/SKILL.md`.
- Create `.codex/skills/security-analysis/SKILL.md`.
- Refine the attached draft role text into skill trigger descriptions, repo-specific instructions, and output formats.
- Ensure each skill points Codex to `AGENTS.md`, specs, tasks, and ADRs before review conclusions.
- Update spec/task indexes so the new work is discoverable.

## Out of Scope

- Adding non-review skills.
- Adding UI metadata such as `agents/openai.yaml`.
- Changing application runtime behavior.

## Acceptance Criteria

- [x] All three skills exist under `.codex/skills/` with a `SKILL.md`.
- [x] `architecture-review` and `project-coherence-review` have clearly separated trigger conditions.
- [x] `security-analysis` explicitly covers passkeys, sessions, CSRF, PostgreSQL, containers, OCI, and secret handling.
- [x] Each skill instructs Codex to read `AGENTS.md` plus the relevant spec/task/ADR files first.
- [x] `docs/spec/README.md` and `docs/tasks/README.md` reference the new spec and task.
