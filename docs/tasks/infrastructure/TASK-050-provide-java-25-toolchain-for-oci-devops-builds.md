---
id: TASK-050
title: Provide Java 25 Toolchain for OCI DevOps Builds
status: in_progress
category: infrastructure
related_features:
  - SPEC-003
owner: @aattard
created: 2026-04-12
updated: 2026-04-13
---

## Summary

Ensure the OCI DevOps build pipeline runs Wort-Werk verification and packaging with a Java 25 toolchain rather than the runner's older default JDK.

## Scope

- Document the Java 25 requirement in the OCI deployment workflow.
- Update the OCI DevOps build execution path so Maven runs with Java 25.
- Update the OCI DevOps build execution path so Maven has the supporting Docker Compose tooling required by the repository verification contract.
- Verify the pipeline setup is reproducible on managed OCI runners rather than relying on operator laptop tooling.
- Cover the build-spec contract with a focused test so Java toolchain regressions fail early in the repository.
- Keep the verification and production container image path on Oracle-distributed Java and Linux base images.
- Use Oracle no-fee base images for the verification path so the repository-tracked local and OCI DevOps workflow does not need a separate Oracle base-image registry login.

## Constraints

- The normal production release path remains OCI DevOps, not a laptop-local build workaround.
- The pipeline must use a supported Oracle-distributed Java 25 toolchain available to OCI-managed runners.
- Toolchain setup must be explicit in repository-tracked configuration so a fresh runner can reproduce the build without manual steps.
- OCI DevOps runners must provision Docker Compose explicitly before `./mvnw clean verify`, because the managed runner image does not provide it reliably by default.
- Verification image builds must stay on Oracle-distributed Java and Linux base images.
- The verification path should prefer Oracle no-fee images that are anonymously pullable rather than adding a second Oracle registry-auth prerequisite to the normal repository gate.

## Out of Scope

- Changing the repository baseline away from Java 25.
- Introducing a separate long-lived custom build VM just to satisfy the Java requirement.
- Reworking unrelated OCI DevOps stages that do not depend on the build JDK.

## Acceptance Criteria

- [ ] Repository docs state that OCI DevOps releases run with Java 25.
- [ ] The OCI DevOps build path installs or selects Java 25 before Maven verification and packaging.
- [ ] The OCI DevOps build path provisions Docker Compose before Maven verification reaches the Compose-backed verification environment steps.
- [ ] A repository test covers the expected Java 25 build-spec contract.
- [ ] The verification image Dockerfile uses Oracle-distributed Java and Linux base images from Oracle's no-fee image path.
- [ ] Local verification and OCI DevOps builds do not require a separate Oracle base-image registry login before building the verification image.
- [ ] A release triggered through OCI DevOps reaches at least the Maven verification step without failing the Java version enforcer.
