# ADR-0003: Require TDD and `./mvnw clean verify` Before Commit

## Status
Accepted

## Context
The project needs a consistent engineering workflow that reduces regressions and makes behavior changes explicit across all threads.

## Decision
Adopt the following mandatory workflow:

1. Before starting any change, verify baseline test health.
2. For functional behavior changes, use test-driven development:
   - add or update a functional test first,
   - run functional tests and confirm the new test fails,
   - implement the change,
   - run tests and confirm the new test passes.
3. Before committing, run `./mvnw clean verify` and require a passing result.

## Consequences
Positive:
- Behavior changes are documented in tests before implementation.
- Regressions are detected earlier through full pipeline verification.
- Collaboration across threads becomes more predictable and auditable.

Negative:
- Slightly longer local iteration due to stricter validation steps.

Risks:
- Developers may skip steps unless workflow is enforced in review/CI.

## Alternatives Considered
- Run only `./mvnw test` before commit: faster, but weaker coverage.
- Test-after coding workflow: simpler, but less disciplined for behavior design.
