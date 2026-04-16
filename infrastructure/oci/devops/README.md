# OCI DevOps Release Stack

This stack provisions the OCI-native release runner foundation described by `TASK-049`.

## What It Provisions

- OCI DevOps project
- OCI Logging log group and DevOps project service log
- GitHub access-token connection
- secret-read policy scoped to the configured GitHub, OCIR, runtime DB, PostgreSQL admin, and runtime TLS Vault secret OCIDs
- build pipeline that checks out an explicit git revision
- OCI Object Storage release-handoff bucket for release bundle and metadata transfer
- deploy pipeline with a private shell stage on the dedicated DevOps subnet
- inline command specification for private rollout execution

## Why This Exists

The private PostgreSQL endpoint and runtime rollout path should not depend on an operator laptop.
This stack moves the release control plane into OCI-managed infrastructure and binds the private shell stage to the dedicated DevOps subnet and NSG.
OCI DevOps managed build runners currently ship JDK 17 by default, so the build spec enables the Oracle JDK repository on Oracle Linux and installs Oracle JDK 25 before running the repository verification flow.
The same build spec must also install the Playwright host libraries with Oracle Linux RPM packages because the managed runners are not Ubuntu hosts and Playwright's `--with-deps` helper falls back to `apt-get`.
The publish step must also use only the build commands and publication modes available on the managed runner, so the repository checks whether it has Docker-style builder bootstrap and inline push support or only a Podman-style manifest workflow before choosing how to publish the runtime image. The current managed OCI runner contract is intentionally constrained to `linux/amd64` because the runner cannot execute the `linux/arm64` build stages required by the current Dockerfile.
The verification image built through `./mvnw clean verify` uses a pinned Oracle no-fee Oracle JDK builder image and an Oracle Linux runtime base, so the build pipeline does not need a separate Oracle JDK base-image registry login before verification.
The managed runner executes `./mvnw clean verify` with the repository Podman-native verification backend, because the managed environment does not provide a reliable Docker daemon-backed Compose runtime.
The private shell stage cannot assume `psql` is preinstalled on the managed OCI shell image, so the command spec provisions the PostgreSQL client before invoking the repository-owned DB bootstrap script.

## Current Boundary

This stack is the intended normal production release path.
The build stage owns verification, commit-traceable image publication, and release-metadata generation.
The deploy stage owns private DB bootstrap and runtime rollout from inside OCI.
That deploy path includes provisioning the PostgreSQL client tooling required by `data/bootstrap-runtime-db-role.sh` on the managed shell host when the base image does not already provide it.

## Required Inputs

Set or write the following values into `terraform.tfvars` or `foundation.auto.tfvars`:

- `region`
- `home_region`
- `compartment_ocid`
- `devops_subnet_id`
- `devops_nsg_id`
- `devops_dynamic_group_name`
- `github_connection_token_secret_ocid`

Optional inputs:

- `repository_url`
- `repository_branch`
- `build_runner_image`
- `shell_stage_shape_name`
- `shell_stage_shape_ocpus`
- `shell_stage_shape_memory_in_gbs`
- `project_log_retention_duration`
- OCI-resident image-push and runtime-deploy inputs documented in `terraform.tfvars`

Required `terraform.tfvars` entries for OCI-managed image publication:

- `github_connection_token_secret_ocid`
- `image_registry_username`
- `image_registry_password_secret_ocid`

## Apply

```bash
cd infrastructure/oci/devops
terraform init
terraform plan
terraform apply
```

The stack now provisions the DevOps project log through OCI Logging, so build runs do not depend on a manual "enable logs" console step.
The stack also provisions the least-privilege secret-read policy for the external GitHub connection token, the OCIR push secret, the runtime DB password secret, the runtime TLS certificate secrets, and the PostgreSQL bootstrap secrets required by the private deploy stage, while `foundation` provisions the baseline DevOps dynamic group and compartment-scoped runner policy.
Release handoff is intentionally modeled as Object Storage upload/download rather than OCI DevOps managed `DELIVER_ARTIFACT` stages because the managed artifact publication path repeatedly failed with opaque OCI internal errors after the build stage had already succeeded.

## Trigger A Release

Use the helper after the stack has been applied:

```bash
./infrastructure/oci/devops/run-release.sh
```

By default it:

- reads `build_pipeline_id` from Terraform output when possible
- targets the current git `HEAD`
- derives `releaseVersion` from the selected commit short SHA
- passes only per-run release selectors; OCI-managed runtime deployment defaults stay on the pipeline definition
- resolves the PostgreSQL CA certificate inside OCI from the configured DB system OCID instead of pushing the certificate through build-run arguments

Before the first OCI DevOps rollout, migrate runtime state into the OCI backend once:

```bash
RUNTIME_BACKEND_MIGRATE=true ./infrastructure/oci/deploy.sh runtime
```

Before applying `devops/` or triggering a release, make sure `runtime/terraform.tfvars` already contains:

- `tls_public_certificate_secret_ocid`
- `tls_private_key_secret_ocid`
- optionally `tls_ca_certificate_secret_ocid`

The recommended path is:

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/runtime/set-tls-secrets.sh
```
