# ADR-0010: Use a Dedicated Non-Admin Runtime DB Role

## Status
Accepted

## Context

Wort-Werk currently defaults the OCI runtime database username to `wortwerk_admin`, and the secret bootstrap flow reuses the PostgreSQL administrator password for runtime access when no separate runtime user is configured. That couples the application runtime to a broader administrative account than the app should need.

The current application also runs Flyway migrations with the same datasource credentials used by the runtime. That means the runtime role still needs enough privilege to manage Wort-Werk-owned schema changes, but it does not need broad instance-level administration such as creating other roles or managing unrelated databases.

## Decision

Adopt the following runtime credential boundary for OCI PostgreSQL:

1. Use a dedicated non-admin runtime DB role for the application.
2. Do not default runtime connectivity to the PostgreSQL administrator account.
3. Keep the runtime password in OCI Vault as a separate secret from the administrator password.
4. Limit the runtime role to Wort-Werk-owned database/schema responsibilities needed by the current application and Flyway usage.

## Consequences

Positive:
- A compromised application runtime no longer starts from the broader administrator account.
- Runtime secret management becomes clearer because administrator and application credentials are no longer implicitly tied together.

Negative:
- A privileged bootstrap path is required to create the runtime role and grant its privileges.
- Because Flyway still uses the application datasource today, the runtime role cannot be reduced to pure DML-only access yet.

Risks:
- If the implementation hides role/grant bootstrap in ad hoc operator steps, the security model will drift and become unreliable.
- If a future migration requires privileges beyond the documented app-owned boundary, the role design must be revisited explicitly rather than expanded casually.

## Alternatives Considered

- Continue using `wortwerk_admin` for runtime: rejected because it keeps the application on an unnecessarily broad account.
- Split migration credentials and runtime credentials immediately: stronger in principle, but not required for this step because the current stack does not yet provide a clean separate migration execution path inside the private OCI network.
