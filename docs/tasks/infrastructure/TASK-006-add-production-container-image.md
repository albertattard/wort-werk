---
id: TASK-006
title: Add Production Container Image
status: done
category: infrastructure
related_features:
  - SPEC-002
owner: @aattard
created: 2026-04-02
updated: 2026-04-02
---

## Summary

Add production containerization for Wort-Werk using a single image with bundled assets.

## Scope

- Add multi-stage `Dockerfile` for build + runtime.
- Use Maven Wrapper in image build stage.
- Bundle `assets/` in runtime image.
- Add `.dockerignore` to minimize build context.

## Assumptions

- Runtime port is `8080`.
- Production image is built from source in this repository.
- No database container is required in this phase.

## Acceptance Criteria

- [x] `Dockerfile` exists and is production-oriented (single runtime image outcome).
- [x] Runtime image contains runnable jar and `assets/`.
- [x] Runtime command starts app with `java -jar`.
- [x] `.dockerignore` excludes unnecessary files.
- [x] `./mvnw clean verify` passes after changes.
