---
id: TASK-034
title: Implement Passkey Auth Foundation
status: completed
category: quiz
related_features:
  - SPEC-005
owner: @aattard
created: 2026-04-09
updated: 2026-04-09
---

## Summary

Replace password-based authentication with passkey-first WebAuthn authentication while keeping the auth scope limited to login/registration/session protection.

## Scope

- Add WebAuthn registration and authentication endpoints.
- Add server-side challenge generation and verification flow.
- Add passkey credential persistence model and migrations.
- Update login/register UI to passkey-first UX.
- Keep quiz routes protected behind authenticated session.
- Remove password fields and password-hash dependency from active login path.

## Out of Scope

- Attempt persistence.
- Noun progress aggregation.
- Adaptive noun selection.
- Progress dashboards/views.
- Multi-factor fallback flows (for example TOTP/SMS).

## Acceptance Criteria

- [x] A new user can register with a passkey and then login with that passkey.
- [x] Existing password-based UI flow is removed from primary user journey.
- [x] Auth data model stores passkey credential data (no `passwordHash` required for primary login).
- [x] Quiz behavior remains functionally intact for authenticated users.
- [x] Progress/attempt/adaptive logic remains out of this task.
- [x] `./mvnw clean verify` passes.
