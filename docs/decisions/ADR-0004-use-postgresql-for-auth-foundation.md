# ADR-0004: Use PostgreSQL for Auth Foundation

## Status
Accepted

## Context
The project is introducing authenticated users as a dedicated workstream before progress/attempt tracking.  
This requires a production-ready relational database with strong Spring Boot support, reliable migrations, and a clear path to later analytics-oriented features.

## Decision
Use PostgreSQL as the primary database for the authentication foundation.

Scope of this decision:
- PostgreSQL is the default database for user/auth data in the current auth-only phase.
- Flyway migrations should target PostgreSQL as the canonical dialect.
- Future progress/attempt features will build on the same PostgreSQL foundation unless superseded by a new ADR.

## Consequences
Positive:
- Strong compatibility with Spring Boot, JPA, and Flyway
- Robust SQL feature set for future reporting/analytics use cases
- Clear path from local development to OCI deployment
- Reduces likelihood of later schema/query rework

Negative:
- Slightly higher setup overhead than embedded-only options
- Team members preferring MySQL must adapt tooling and habits

Risks:
- If runtime environment constraints strongly favor another engine later, migration effort may be needed

## Alternatives Considered
- MySQL: Viable and widely used, but less aligned with expected future query flexibility and analytics-oriented evolution.
- H2/embedded only: Fast for local development, but not suitable as the production source of truth for auth data.
- SQLite: Simple footprint, but weaker fit for concurrent server-side production usage patterns.
