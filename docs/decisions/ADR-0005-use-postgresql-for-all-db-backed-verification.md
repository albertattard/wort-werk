# ADR-0005: Use PostgreSQL for All DB-Backed Verification

## Status
Accepted

## Context
The project currently uses PostgreSQL as the intended runtime database but still relies on H2 for DB-backed verification. This creates a gap between the database exercised in verification and the database used in real runtime behavior. The test taxonomy is also too coarse when DB-backed JVM tests and browser-driven end-to-end tests are both treated as one category.

## Decision
Adopt PostgreSQL as the only database for runtime and DB-backed verification.

Verification taxonomy:
- Untagged tests: fast unit tests, suitable for Surefire `test`
- `@Tag("db")`: PostgreSQL-backed JVM integration tests, suitable for Failsafe `integration-test`/`verify`
- `@Tag("e2e")`: browser-driven end-to-end tests, suitable for Failsafe `integration-test`/`verify`

Scope of this decision:
- H2 should not be required for application runtime or container-based verification.
- Surefire should exclude both `db` and `e2e`.
- Failsafe should own all DB-backed and browser-based verification.

## Consequences
Positive:
- Verification is closer to production behavior because one real database is exercised.
- Test categories become clearer and easier to reason about.
- Schema and SQL issues are more likely to be caught before commit.

Negative:
- Verification setup is heavier because PostgreSQL must be provisioned during `verify`.
- Local feedback for DB-backed tests is slower than embedded-database testing.

Risks:
- Poorly isolated DB tests can make `verify` flaky unless setup and teardown are disciplined.

## Alternatives Considered
- Keep H2 for verification: simpler startup, but lower fidelity and higher dialect risk.
- Mark all DB-backed tests as `e2e`: simpler taxonomy, but less precise and harder to reason about.
- Use PostgreSQL only for browser tests and keep H2 for JVM DB tests: inconsistent verification target.
