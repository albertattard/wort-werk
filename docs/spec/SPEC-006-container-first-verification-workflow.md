---
id: SPEC-006
title: Container-First Verification Workflow
status: proposed
priority: high
owner: @aattard
last_updated: 2026-04-05
---

## Problem

Current verification primarily targets the JVM process launched by Maven. The desired verification target is the production container image, built from current source at verification time.

## Goal

Define one primary pre-commit workflow where `./mvnw verify` validates a freshly built container image with the existing Playwright e2e tests.

## Required Order

1. Run fast code-level tests:
   - `./mvnw test`
2. Run Maven verification:
   - `./mvnw verify`
3. During `verify`, Maven must execute:
   1. build the container image from current workspace code,
   2. run container from that exact image tag,
   3. run Playwright e2e against container URL,
   4. stop/remove container.
4. Commit only when all above steps pass.

## Freshness Guarantee

- `verify` must not test a stale image tag.
- Image tag should be unique per build (recommended: current git commit SHA).
- The same generated tag must be used for both `docker run` and e2e target wiring.

## Scope

- Reuse existing Playwright Java e2e coverage.
- Do not create a separate test framework.
- Keep commands documented and copy-paste ready.
- Keep `./mvnw verify` as the single command for container-based e2e verification.

## Acceptance Criteria

- [ ] Repository docs define `./mvnw verify` as the container e2e gate.
- [ ] `verify` builds a fresh image from current code and does not rely on stale tags.
- [ ] `verify` runs Playwright e2e against the started container.
- [ ] `verify` stops/removes the container after tests.
- [ ] Current workflow docs are aligned (no conflicting mandatory gate language).
- [ ] `./mvnw test` still passes as the fast baseline gate.
