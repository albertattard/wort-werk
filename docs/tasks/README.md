# Tasks

File-based task tracker for Wort-Werk.

## Workflow

1. Create or update a `SPEC` in `docs/spec/`.
2. Create a `TASK` linked to the spec in `docs/tasks/`.
3. Verify baseline: run tests and ensure they pass before making changes.
4. Apply TDD for functional behavior:
   - create or update a functional test first,
   - run functional tests and confirm the new test fails,
   - implement the change,
   - run tests again and confirm it passes.
5. Run `./mvnw clean verify` before committing.
6. Move task status to `done` after acceptance criteria pass.

## Task Metadata

New task files must include these front matter fields:
- `id`
- `title`
- `status`
- `category`
- `related_features`
- `owner`
- `created`
- `updated`

## Task Categories

Use one of these `category` values for new tasks:
- `quiz`
- `content`
- `agentic`
- `infrastructure`
- `repo-process`

## Task Files

- [TASK-001: Implement SPEC-001 Quiz Vertical Slice](./quiz/TASK-001-implement-spec-001-quiz-vertical-slice.md)
- [TASK-002: Enforce Correct Selection Before Advancing and Show Noun](./quiz/TASK-002-enforce-correct-before-advance-and-show-noun.md)
- [TASK-003: Center Noun and Article Buttons](./quiz/TASK-003-center-noun-and-article-buttons.md)
- [TASK-004: Use UI Clicks in Functional Tests](./quiz/TASK-004-use-ui-clicks-in-functional-tests.md)
- [TASK-005: Add Audio Cues for Prompt and Correct Answer](./quiz/TASK-005-add-audio-cues-for-prompt-and-correct-answer.md)
- [TASK-013: Support Umlaut Asset Path Normalization](./quiz/TASK-013-support-umlaut-asset-path-normalization.md)
- [TASK-014: Sync CSV with Image Catalog and Generate Audio](./quiz/TASK-014-sync-csv-with-image-catalog-and-generate-audio.md)
- [TASK-021: Use HTMX Fragment Updates for Quiz Actions](./quiz/TASK-021-use-htmx-fragment-updates-for-quiz-actions.md)
- [TASK-024: Roll Out User Auth and Progress Tracking](./quiz/TASK-024-user-auth-and-progress-rollout-plan.md)
- [TASK-033: Implement Auth Foundation with PostgreSQL](./quiz/TASK-033-auth-foundation-with-postgresql.md)
- [TASK-034: Implement Passkey Auth Foundation](./quiz/TASK-034-implement-passkey-auth-foundation.md)
- [TASK-016: Add Update Assets Trigger Workflow](./repo-process/TASK-016-add-update-assets-trigger-workflow.md)
- [TASK-025: Adopt Container-First Verification Workflow](./repo-process/TASK-025-adopt-container-first-verification-workflow.md)
- [TASK-019: Generate 420px Image Variants While Preserving Originals](./content/TASK-019-generate-420px-image-variants.md)
- [TASK-022: Separate Original and Derived Image Directories](./content/TASK-022-separate-original-and-derived-image-directories.md)
- [TASK-023: Sync Missing Nouns and Regenerate Missing Derived Assets](./content/TASK-023-sync-missing-nouns-images-and-audio.md)
- [TASK-035: Ingest New School Noun Assets](./content/TASK-035-ingest-new-school-noun-assets.md)
- [TASK-006: Add Production Container Image](./infrastructure/TASK-006-add-production-container-image.md)
- [TASK-007: Prepare OCI Container Instance Deployment](./infrastructure/TASK-007-prepare-oci-container-instance-deployment.md)
- [TASK-008: Split OCI IaC into Foundation and Runtime Stacks](./infrastructure/TASK-008-split-oci-iac-foundation-and-runtime.md)
- [TASK-009: Automate OCI Build Push and Runtime Deploy](./infrastructure/TASK-009-automate-build-push-runtime-deploy.md)
- [TASK-010: Support Private OCIR Pull Credentials for Runtime](./infrastructure/TASK-010-support-private-ocir-pull-credentials.md)
- [TASK-011: Harden Release Cleanup with OCIR Repository ID](./infrastructure/TASK-011-harden-release-cleanup-with-ocir-repository-id.md)
- [TASK-012: Add Runtime Access URL Output](./infrastructure/TASK-012-add-runtime-access-url-output.md)
- [TASK-015: Add Stable Endpoint via OCI Load Balancer](./infrastructure/TASK-015-add-stable-endpoint-via-oci-load-balancer.md)
- [TASK-026: Enforce clean verify Before OCI Release](./infrastructure/TASK-026-enforce-clean-verify-before-oci-release.md)
- [TASK-017: Document Manual Let's Encrypt TLS Issuance and Renewal](./infrastructure/TASK-017-document-manual-lets-encrypt-renewal.md)
- [TASK-018: Manage TLS Certificate and HTTPS Listener Through Terraform](./infrastructure/TASK-018-manage-tls-certificate-through-terraform.md)
- [TASK-020: Reduce Deploy 502 with Overlap and Readiness Health Checks](./infrastructure/TASK-020-reduce-deploy-502-with-overlap-and-readiness-health-checks.md)
- [TASK-027: Add Repeatable OCI Full Rollout Command](./infrastructure/TASK-027-add-repeatable-oci-full-rollout-command.md)
- [TASK-028: Enforce Clean Worktree for OCI Rollout](./infrastructure/TASK-028-enforce-clean-rollout-worktree.md)
- [TASK-029: Add tools/rollout Wrapper for OCI Rollout](./infrastructure/TASK-029-add-tools-rollout-wrapper.md)
- [TASK-030: Resolve Runtime image_tag Automatically in Rollout](./infrastructure/TASK-030-resolve-runtime-image-tag-for-rollout.md)
- [TASK-031: Split Verify Local Build and Release Multi-Arch Publish](./infrastructure/TASK-031-split-verify-local-build-and-release-multiarch-publish.md)
- [TASK-032: Fix Rollout Order for Multi-Arch Release](./infrastructure/TASK-032-fix-rollout-order-for-multiarch-release.md)

## Pending

- [ ] [TASK-024: Roll Out User Auth and Progress Tracking](./quiz/TASK-024-user-auth-and-progress-rollout-plan.md)
- [ ] [TASK-034: Implement Passkey Auth Foundation](./quiz/TASK-034-implement-passkey-auth-foundation.md)

## In Progress

- (none)

## Done

- [x] [TASK-001: Implement SPEC-001 Quiz Vertical Slice](./quiz/TASK-001-implement-spec-001-quiz-vertical-slice.md)
- [x] [TASK-002: Enforce Correct Selection Before Advancing and Show Noun](./quiz/TASK-002-enforce-correct-before-advance-and-show-noun.md)
- [x] [TASK-003: Center Noun and Article Buttons](./quiz/TASK-003-center-noun-and-article-buttons.md)
- [x] [TASK-004: Use UI Clicks in Functional Tests](./quiz/TASK-004-use-ui-clicks-in-functional-tests.md)
- [x] [TASK-005: Add Audio Cues for Prompt and Correct Answer](./quiz/TASK-005-add-audio-cues-for-prompt-and-correct-answer.md)
- [x] [TASK-013: Support Umlaut Asset Path Normalization](./quiz/TASK-013-support-umlaut-asset-path-normalization.md)
- [x] [TASK-014: Sync CSV with Image Catalog and Generate Audio](./quiz/TASK-014-sync-csv-with-image-catalog-and-generate-audio.md)
- [x] [TASK-033: Implement Auth Foundation with PostgreSQL](./quiz/TASK-033-auth-foundation-with-postgresql.md)
- [x] [TASK-016: Add Update Assets Trigger Workflow](./repo-process/TASK-016-add-update-assets-trigger-workflow.md)
- [x] [TASK-025: Adopt Container-First Verification Workflow](./repo-process/TASK-025-adopt-container-first-verification-workflow.md)
- [x] [TASK-019: Generate 420px Image Variants While Preserving Originals](./content/TASK-019-generate-420px-image-variants.md)
- [x] [TASK-022: Separate Original and Derived Image Directories](./content/TASK-022-separate-original-and-derived-image-directories.md)
- [x] [TASK-023: Sync Missing Nouns and Regenerate Missing Derived Assets](./content/TASK-023-sync-missing-nouns-images-and-audio.md)
- [x] [TASK-035: Ingest New School Noun Assets](./content/TASK-035-ingest-new-school-noun-assets.md)
- [x] [TASK-021: Use HTMX Fragment Updates for Quiz Actions](./quiz/TASK-021-use-htmx-fragment-updates-for-quiz-actions.md)
- [x] [TASK-006: Add Production Container Image](./infrastructure/TASK-006-add-production-container-image.md)
- [x] [TASK-007: Prepare OCI Container Instance Deployment](./infrastructure/TASK-007-prepare-oci-container-instance-deployment.md)
- [x] [TASK-008: Split OCI IaC into Foundation and Runtime Stacks](./infrastructure/TASK-008-split-oci-iac-foundation-and-runtime.md)
- [x] [TASK-009: Automate OCI Build Push and Runtime Deploy](./infrastructure/TASK-009-automate-build-push-runtime-deploy.md)
- [x] [TASK-010: Support Private OCIR Pull Credentials for Runtime](./infrastructure/TASK-010-support-private-ocir-pull-credentials.md)
- [x] [TASK-011: Harden Release Cleanup with OCIR Repository ID](./infrastructure/TASK-011-harden-release-cleanup-with-ocir-repository-id.md)
- [x] [TASK-012: Add Runtime Access URL Output](./infrastructure/TASK-012-add-runtime-access-url-output.md)
- [x] [TASK-015: Add Stable Endpoint via OCI Load Balancer](./infrastructure/TASK-015-add-stable-endpoint-via-oci-load-balancer.md)
- [x] [TASK-026: Enforce clean verify Before OCI Release](./infrastructure/TASK-026-enforce-clean-verify-before-oci-release.md)
- [x] [TASK-017: Document Manual Let's Encrypt TLS Issuance and Renewal](./infrastructure/TASK-017-document-manual-lets-encrypt-renewal.md)
- [x] [TASK-018: Manage TLS Certificate and HTTPS Listener Through Terraform](./infrastructure/TASK-018-manage-tls-certificate-through-terraform.md)
- [x] [TASK-020: Reduce Deploy 502 with Overlap and Readiness Health Checks](./infrastructure/TASK-020-reduce-deploy-502-with-overlap-and-readiness-health-checks.md)
- [x] [TASK-027: Add Repeatable OCI Full Rollout Command](./infrastructure/TASK-027-add-repeatable-oci-full-rollout-command.md)
- [x] [TASK-028: Enforce Clean Worktree for OCI Rollout](./infrastructure/TASK-028-enforce-clean-rollout-worktree.md)
- [x] [TASK-029: Add tools/rollout Wrapper for OCI Rollout](./infrastructure/TASK-029-add-tools-rollout-wrapper.md)
- [x] [TASK-030: Resolve Runtime image_tag Automatically in Rollout](./infrastructure/TASK-030-resolve-runtime-image-tag-for-rollout.md)
- [x] [TASK-031: Split Verify Local Build and Release Multi-Arch Publish](./infrastructure/TASK-031-split-verify-local-build-and-release-multiarch-publish.md)
- [x] [TASK-032: Fix Rollout Order for Multi-Arch Release](./infrastructure/TASK-032-fix-rollout-order-for-multiarch-release.md)

## Blocked

- (none)
