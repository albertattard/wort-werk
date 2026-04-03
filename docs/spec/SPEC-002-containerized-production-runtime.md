---
id: SPEC-002
title: Containerized Production Runtime
status: in_progress
priority: medium
owner: @aattard
last_updated: 2026-04-02
---

## Problem

The application currently runs from a local JVM setup only. We need a reproducible production image that can be built and run consistently across environments.

## User-facing Behavior

Operations can build one production container image and run the app from that image.

The image includes static content required by the app (`assets/`) so no external volume is required.

## Inputs/Outputs

Input:
- build the image from repository source
- run the image with a mapped HTTP port

Output:
- one runnable container image that starts the Spring Boot application
- app serves quiz data/images/audio from bundled `assets/`

## Acceptance Criteria

- [x] Repository contains a multi-stage production `Dockerfile`.
- [x] Build stage uses Maven Wrapper and project sources to produce the runnable jar.
- [x] Runtime stage includes only runtime dependencies plus app jar and `assets/`.
- [x] Container starts the app via `java -jar`.
- [x] Container exposes port `8080`.
- [x] `.dockerignore` excludes unnecessary build context content (`target/`, `.git/`, IDE artifacts).

## Non-goals

- Development hot-reload container workflows.
- Database service/container orchestration.
- Multi-container production topology.
