---
id: TASK-025
title: Adopt Container-First Verification Workflow
status: done
category: repo-process
related_features:
  - SPEC-006
owner: @aattard
created: 2026-04-05
updated: 2026-04-05
---

## Summary

Adopt and document a Maven-driven container-first pre-commit verification flow where `./mvnw clean verify` builds, runs, and tests the container image for current code.

## Scope

- Document the ordered verification workflow from SPEC-006.
- Wire Maven lifecycle so `verify` orchestrates container build/run/e2e/stop.
- Align workflow docs (`AGENTS.md`, task/spec indexes, and related guidance) to avoid conflicting gate requirements.
- Ensure image freshness by deriving a unique tag for current build (recommended: git SHA).

## Out of Scope

- Rewriting e2e tests in a different framework.
- Changing application behavior.

## Acceptance Criteria

- [x] Workflow order is documented exactly as:
  1. `./mvnw clean verify` (container build + run + e2e + stop)
  2. commit on success
- [x] `verify` builds container image from current code and tags it uniquely.
- [x] `verify` starts container from that tag and runs existing Playwright e2e against it.
- [x] `verify` always stops/removes test container.
- [x] `AGENTS.md` commit/verification flow is updated to match this workflow.
- [x] Conflicting workflow statements are updated.
