# Wort-Werk

Wort-Werk is a Java-based German article trainer built with a specification-first workflow.

## Source of Truth

The product specification in `docs/spec/` is the authoritative source for behavior and requirements.
Code is an implementation of those specs.

## Working Model

1. Define or update the specification first.
2. Create a linked task in `docs/tasks/`.
3. Verify a clean baseline before changes: all tests must pass.
4. Use TDD for behavior changes:
   - add or update a functional test first,
   - run functional tests and confirm the new test fails,
   - implement the change,
   - re-run tests and confirm the new test passes.
5. Update task/spec status only after acceptance criteria pass.

## Documentation Structure

```text
docs/
  spec/
    Product-Vision.md
    SPEC-001-*.md
  decisions/
    ADR-0001-*.md
  tasks/
    TASK-001-*.md
```

## Asset Catalog

- `assets/images/new/` is an inbox-only staging directory for newly dropped source images.
- `assets/images/original/<category>/` stores categorized source images.
- `assets/images/420/<category>/` stores categorized resized variants used by the app.
- `assets/articles.csv` is the asset catalog source of truth and includes a stable `Id` plus `Category` for each row.
- Technical filenames remain ASCII-safe; learner-facing noun/article text comes from CSV metadata.

## Testing Conventions

- Use AssertJ as the default assertion library for all tests.
- Use untagged tests for fast unit tests.
- Use `@Tag("db")` for PostgreSQL-backed JVM integration tests.
- Use `@Tag("e2e")` for browser-driven end-to-end tests.
- Use `./mvnw test` for fast tests only; it excludes both `@Tag("db")` and `@Tag("e2e")`.
- Use `./mvnw clean verify` to run the full pipeline, including `@Tag("db")` and `@Tag("e2e")` tests.
- Maven uses Docker Compose to orchestrate the local verification `app` + PostgreSQL stack during `verify`.
- Set `VERIFY_DB_USERNAME` and `VERIFY_DB_PASSWORD` in the environment before `./mvnw clean verify`; verification fails fast if either is missing.
- Recommended pre-commit order:
  1. `export VERIFY_DB_USERNAME='<username>'`
  2. `export VERIFY_DB_PASSWORD='<password>'`
  3. `./mvnw clean verify`
- Use `./mvnw clean verify` as the required pre-commit validation command.

## OCI Release Note

- The in-progress OCI DevOps release path is provisioned through `infrastructure/oci/devops/`.
- This path depends on explicit OCI IAM bindings for the DevOps runner; private networking alone is not sufficient.
- Private DevOps runners also need a dedicated outbound path for external SCM fetches; do not assume the runtime subnet's private-only network policy is sufficient for release execution.
- Treat DevOps dynamic groups and compartment-scoped policies as part of the release infrastructure contract, not as post-apply console cleanup.

## Container

Use the production image definition in `container/Dockerfile`.

Single-architecture local build (example: amd64):

```bash
docker build \
  --file ./container/Dockerfile \
  --tag game:wort-werk \
  --platform linux/amd64 \
  --load \
  .
```

Run and stop locally:

```bash
docker run \
  --rm \
  --detach \
  --name wort-werk \
  --publish 8080:8080 \
  game:wort-werk

docker stop wort-werk
```

For multi-architecture publishing (`linux/amd64` + `linux/arm64`) see [container/README.md](./container/README.md).
