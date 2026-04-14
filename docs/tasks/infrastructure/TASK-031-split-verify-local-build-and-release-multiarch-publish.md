---
id: TASK-031
title: Split Verify Local Build and Release Multi-Arch Publish
status: done
category: infrastructure
related_features:
  - SPEC-003
  - SPEC-006
owner: @aattard
created: 2026-04-06
updated: 2026-04-14
---

## Summary

Enforce separation between verification and release publishing: `./mvnw clean verify` must build/run a local single-platform test image only, while OCI release must publish multi-architecture images (`linux/amd64,linux/arm64`) to OCIR.

## Scope

- Update Maven verify container build step to local-only image build (no push).
- Update OCI release automation to publish a multi-arch image with an OCI-runner-compatible publication flow rather than assuming local Docker Buildx `--push` semantics.
- Keep runtime deploy consuming immutable `image_tag`.
- Update OCI and workflow docs to match the split.

## Out of Scope

- Cross-architecture e2e execution in verify.
- Changing quiz application behavior.

## Acceptance Criteria

- [x] `./mvnw clean verify` builds local image and does not push to registry.
- [x] `./mvnw clean verify` still runs existing Playwright e2e against container.
- [x] `deploy.sh release` publishes multi-arch image (`linux/amd64,linux/arm64`) before runtime apply.
- [x] Docs/specs describe the verify-vs-release split clearly.
- [x] `./mvnw clean verify` passes after implementation.
