---
id: TASK-053
title: Add Shared Build Footer
status: completed
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-18
updated: 2026-04-18
---

## Summary

Add a shared application footer that shows the current build hash on login, registration, and quiz pages so operators can confirm which build is live.

## Scope

- Add a footer that renders on all current application pages.
- Show a build label in the form `Build: <hash>`.
- Source the build hash from the application/runtime build metadata rather than hardcoding per page.
- Keep local verification and OCI deployment behavior aligned.

## Out of Scope

- Adding a shared header.
- Redesigning the full application shell beyond the footer needed for build visibility.

## Acceptance Criteria

- [x] Login page shows a footer containing `Build:`.
- [x] Registration page shows a footer containing `Build:`.
- [x] Quiz page shows a footer containing `Build:`.
- [x] The build label is supplied through one shared application path rather than duplicated per controller.
- [x] `./mvnw clean verify` passes after implementation.
