# OCI DevOps Release Stack

This stack provisions the OCI-native release runner foundation described by `TASK-049`.

## What It Provisions

- OCI DevOps project
- OCI Logging log group and DevOps project service log
- GitHub access-token connection
- GitHub secret-read policy scoped to the configured Vault secret OCID
- build pipeline that checks out an explicit git revision
- OCI Object Storage release-handoff bucket for release bundle and metadata transfer
- deploy pipeline with a private shell stage on the dedicated DevOps subnet
- inline command specification for private rollout execution

## Why This Exists

The private PostgreSQL endpoint and runtime rollout path should not depend on an operator laptop.
This stack moves the release control plane into OCI-managed infrastructure and binds the private shell stage to the dedicated DevOps subnet and NSG.

## Current Boundary

This stack is the intended normal production release path.
The build stage owns verification, commit-traceable image publication, and release-metadata generation.
The deploy stage owns private DB bootstrap and runtime rollout from inside OCI.

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
The stack also provisions the secret-read policy for the external GitHub connection token, while `foundation` provisions the baseline DevOps dynamic group and compartment-scoped runner policy.
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
- passes the OCI-managed runtime deployment inputs needed by the build/deploy stages

Before the first OCI DevOps rollout, migrate runtime state into the OCI backend once:

```bash
RUNTIME_BACKEND_MIGRATE=true ./infrastructure/oci/deploy.sh runtime
```
