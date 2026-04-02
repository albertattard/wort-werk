# ADR-0001: Use Java with Spring Boot, Thymeleaf, and Maven

## Status
Accepted

## Context
The project goal is to build a small experimental German-article trainer quickly while keeping implementation in Java. The MVP needs a simple UI that shows local images and captures `der`/`die`/`das` answers with immediate feedback and session scoring.

The team preference is to work in Java.

## Decision
Use Java as the implementation language with the following stack:
- Spring Boot for application structure and HTTP handling
- Thymeleaf for server-rendered HTML UI
- Maven for build and dependency management

For initial persistence, use local JSON files (dataset and basic learner progress) to keep the MVP lightweight.

## Consequences
Positive:
- Aligns with preferred language and existing workflow
- Fast MVP delivery without SPA/frontend build complexity
- Single technology ecosystem for backend and UI rendering

Negative:
- Less client-side interactivity than a SPA by default
- Future rich UI interactions may require additional frontend work

Risks:
- Template-driven UI can become harder to evolve if interaction complexity grows quickly

## Alternatives Considered
- React + TypeScript + API backend: More frontend flexibility, but higher initial setup and split-stack complexity
- JavaFX desktop app: Strong Java alignment, but more distribution and UX complexity for this web-oriented learning flow
- Kotlin + Ktor: Modern JVM option, but not aligned with explicit Java preference
