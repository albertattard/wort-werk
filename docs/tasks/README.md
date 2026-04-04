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
- [TASK-006: Add Production Container Image](./infrastructure/TASK-006-add-production-container-image.md)
- [TASK-007: Prepare OCI Container Instance Deployment](./infrastructure/TASK-007-prepare-oci-container-instance-deployment.md)
- [TASK-008: Split OCI IaC into Foundation and Runtime Stacks](./infrastructure/TASK-008-split-oci-iac-foundation-and-runtime.md)
- [TASK-009: Automate OCI Build Push and Runtime Deploy](./infrastructure/TASK-009-automate-build-push-runtime-deploy.md)
- [TASK-010: Support Private OCIR Pull Credentials for Runtime](./infrastructure/TASK-010-support-private-ocir-pull-credentials.md)
- [TASK-011: Harden Release Cleanup with OCIR Repository ID](./infrastructure/TASK-011-harden-release-cleanup-with-ocir-repository-id.md)
- [TASK-012: Add Runtime Access URL Output](./infrastructure/TASK-012-add-runtime-access-url-output.md)
- [TASK-015: Add Stable Endpoint via OCI Load Balancer](./infrastructure/TASK-015-add-stable-endpoint-via-oci-load-balancer.md)

## Pending

- (none)

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
- [x] [TASK-006: Add Production Container Image](./infrastructure/TASK-006-add-production-container-image.md)
- [x] [TASK-007: Prepare OCI Container Instance Deployment](./infrastructure/TASK-007-prepare-oci-container-instance-deployment.md)
- [x] [TASK-008: Split OCI IaC into Foundation and Runtime Stacks](./infrastructure/TASK-008-split-oci-iac-foundation-and-runtime.md)
- [x] [TASK-009: Automate OCI Build Push and Runtime Deploy](./infrastructure/TASK-009-automate-build-push-runtime-deploy.md)
- [x] [TASK-010: Support Private OCIR Pull Credentials for Runtime](./infrastructure/TASK-010-support-private-ocir-pull-credentials.md)
- [x] [TASK-011: Harden Release Cleanup with OCIR Repository ID](./infrastructure/TASK-011-harden-release-cleanup-with-ocir-repository-id.md)
- [x] [TASK-012: Add Runtime Access URL Output](./infrastructure/TASK-012-add-runtime-access-url-output.md)
- [x] [TASK-015: Add Stable Endpoint via OCI Load Balancer](./infrastructure/TASK-015-add-stable-endpoint-via-oci-load-balancer.md)

## Blocked

- (none)
