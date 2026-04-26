---
id: TASK-055
title: Add GitHub Push Triggered OCI App Release
status: in_progress
category: infrastructure
related_features:
  - SPEC-009
owner: @aattard
created: 2026-04-26
updated: 2026-04-26
---

## Summary

Define and implement the trunk-based GitHub-to-OCI application release trigger for Wort-Werk, including path filtering, verified-image handoff, post-switch observation, and rollback behavior.

## Scope

- Configure OCI DevOps or the repository's GitHub/OCI integration so pushes to the trunk branch can start the application release pipeline automatically.
- Skip the application release pipeline for pushes where every changed path is under `docs/**` or `infrastructure/**`.
- Keep Terraform/foundation/data/OKE/DevOps infrastructure changes outside the automatic application release path.
- Build one candidate runtime container image for the pushed git revision.
- Run functional, database-backed, and e2e verification against the exact candidate image that will be deployed.
- Publish the verified image to OCIR using an immutable, commit-traceable reference.
- Deploy the verified image to the inactive OKE blue/green slot by immutable tag or digest.
- Keep the previously active slot running during the post-switch observation window.
- Roll traffic back to the previous slot and stop the failed target slot if qualifying HTTP errors are observed after traffic switches.
- Decommission the previous slot only after post-switch observation succeeds.

## Constraints

- The repository follows trunk-based development; the automatic trigger is for the trunk branch only.
- Documentation-only pushes under `docs/**` must not trigger the application release pipeline.
- Infrastructure-only pushes under `infrastructure/**` must not trigger the application release pipeline.
- Changes outside `docs/**` and `infrastructure/**` are treated as application/runtime-affecting unless this task introduces a narrower tested ignore list.
- The pipeline must not test one image and deploy another.
- The deployment stage must fail closed if it cannot prove the image reference came from the verified pipeline run.
- Infrastructure changes remain manually triggered from the operator laptop.

## Out of Scope

- Editing closed historical tasks that documented earlier release-runner scope.
- Automatically applying Terraform infrastructure changes from GitHub pushes.
- Multi-environment promotion workflows.
- Branch-based release policies beyond the single trunk branch.

## Acceptance Criteria

- [ ] OCI DevOps or repository integration starts the application release pipeline automatically for eligible trunk pushes.
- [ ] Documentation-only pushes under `docs/**` do not start the application release pipeline.
- [ ] Infrastructure-only pushes under `infrastructure/**` do not start the application release pipeline.
- [ ] A mixed push that includes application/runtime paths and docs or infrastructure paths still starts the application release pipeline.
- [ ] The build pipeline records the exact git revision that triggered the release.
- [ ] The build pipeline creates one candidate runtime image and runs verification against that same image.
- [ ] The verified image is published to OCIR with an immutable, commit-traceable reference.
- [ ] The deploy pipeline deploys the verified image by immutable tag or digest and rejects missing or mismatched image metadata.
- [ ] The deploy pipeline keeps the previous slot running during post-switch observation.
- [ ] The deploy pipeline rolls traffic back to the previous slot and stops the failed target slot when qualifying HTTP errors are observed.
- [ ] The deploy pipeline decommissions the previous slot only after the observation window passes.
- [ ] Repository documentation explains the trigger scope, path filtering, verified-image contract, and manual infrastructure boundary.
