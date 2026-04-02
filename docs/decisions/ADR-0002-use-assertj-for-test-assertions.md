# ADR-0002: Use AssertJ for Test Assertions

## Status
Accepted

## Context
The project uses multiple test layers (MockMvc and Playwright E2E). Without a single assertion style, tests become inconsistent and harder to read and maintain across threads.

## Decision
Use AssertJ as the default assertion library for all test code in this repository.

Guidelines:
- Prefer `org.assertj.core.api.Assertions.assertThat`.
- Do not add new assertion frameworks for new tests unless explicitly justified.
- Existing tests should be migrated to AssertJ when touched.

## Consequences
Positive:
- Consistent test style across unit, integration, and E2E tests
- Better readability and fluent assertion chains
- Easier onboarding for contributors and AI-assisted threads

Negative:
- Small migration overhead when updating older tests

Risks:
- Temporary mixed style may exist until legacy tests are fully migrated

## Alternatives Considered
- JUnit assertions only: Simpler baseline but less expressive for richer assertions
- Hamcrest matchers: Flexible, but less consistent with current fluent assertion style
