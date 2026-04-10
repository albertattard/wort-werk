# ADR-0007: Use Repo-Local Review Skills at Explicit Workflow Checkpoints

## Status
Accepted

## Context

Wort-Werk now has repo-local review skills for architecture, project coherence, and security. Without a documented workflow, these skills will either be forgotten or overused. Forgetting them weakens review quality; overusing them on every trivial change adds noise and slows down work without improving outcomes.

## Decision

Adopt the repo-local review skills as conditional workflow checkpoints:

1. Use `architecture-review` for design-heavy work before implementation, especially for:
   - design proposals,
   - ADR-impacting changes,
   - larger refactors,
   - repository-direction questions.
2. Use `project-coherence-review` before commit for non-trivial code changes where consistency with repository patterns matters.
3. Use `security-analysis` for authentication, sessions, CSRF, database access, containers, deployment, secrets, OCI, or any change with meaningful security exposure.
4. Do not require all three skills for every task. Small, local, low-risk changes may not need any skill.
5. Skills remain review aids only; specs, tasks, and ADRs remain the source of truth.

## Consequences

Positive:
- Repo-local skills become part of normal practice instead of ad hoc prompting.
- Review effort is targeted where it provides value.
- Future threads have clearer expectations for when to apply architecture, coherence, and security lenses.

Negative:
- Skill usage still depends on human judgment and can be skipped.
- Some borderline cases will still require explicit judgment about which skill fits best.

Risks:
- If the trigger boundaries drift, architecture and coherence reviews may overlap and lose clarity.

## Alternatives Considered

- Require all skills on every change: consistent, but too heavy and noisy.
- Leave skill usage undocumented: flexible, but unreliable and easy to forget.
