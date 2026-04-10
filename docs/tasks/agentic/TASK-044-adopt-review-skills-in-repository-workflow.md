---
id: TASK-044
title: Adopt Review Skills in Repository Workflow
status: done
category: agentic
related_features:
  - SPEC-007
owner: @aattard
created: 2026-04-10
updated: 2026-04-10
---

## Summary

Document how the repo-local review skills are used in practice so future threads apply them consistently without turning them into noisy mandatory gates on every small change.

## Scope

- Extend `SPEC-007` with workflow adoption rules for the three review skills.
- Add an ADR that captures when skills are expected as part of the engineering workflow.
- Update `AGENTS.md` to document when to use `architecture-review`, `project-coherence-review`, and `security-analysis`.
- Update spec/task/decision indexes as needed.

## Out of Scope

- Adding more skills.
- Making all skills mandatory for every task.
- Enforcing skill usage mechanically in tooling.

## Acceptance Criteria

- [x] `SPEC-007` documents how the review skills fit into the repository workflow.
- [x] `AGENTS.md` includes a concise workflow section for review skill usage.
- [x] The workflow distinguishes between design review, coherence review, and security review.
- [x] The workflow keeps skill usage conditional rather than mandatory for every change.
- [x] ADR and index files are updated to reflect the new workflow rule.
