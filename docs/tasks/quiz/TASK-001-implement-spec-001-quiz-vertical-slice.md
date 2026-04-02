---
id: TASK-001
title: Implement SPEC-001 Quiz Vertical Slice
status: done
category: quiz
related_features:
  - SPEC-001
owner: @aattard
created: 2026-04-02
updated: 2026-04-02
---

## Summary

Implement the first end-to-end quiz flow for image-based German article practice.

## Scope

- Spring Boot application scaffold
- Thymeleaf quiz page with one image prompt
- Three answer buttons (`der`, `die`, `das`)
- Immediate correctness feedback with correct article+noun
- 10-round session and final score
- Data loaded from `assets/articles.csv`

## Assumptions

- The CSV remains the source of truth for MVP nouns/articles/image paths.
- Images are served from the local project assets.

## Acceptance Criteria

- [x] Spring Boot app starts locally.
- [x] Quiz page is reachable in a browser.
- [x] A quiz round displays one image and the three article options.
- [x] Submitting an answer shows immediate feedback.
- [x] Session ends after 10 rounds with a final score.
- [x] No learner-facing English text appears.

## Notes

This task implements `SPEC-001` only. Adaptive agentic behavior will be tracked in a later spec/task.
