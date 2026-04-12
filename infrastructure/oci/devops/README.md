# OCI DevOps Release Stack

This stack provisions the OCI-native release runner foundation described by `TASK-049`.

## What It Provisions

- OCI DevOps project
- OCI Logging log group and DevOps project service log
- GitHub access-token connection
- GitHub secret-read policy scoped to the configured Vault secret OCID
- build pipeline that checks out an explicit git revision
- generic artifact repository for release bundle handoff
- deploy pipeline with a private shell stage on the dedicated DevOps subnet
- inline command specification and release-bundle artifact definitions

## Why This Exists

The private PostgreSQL endpoint and runtime rollout path should not depend on an operator laptop.
This stack moves the release control plane into OCI-managed infrastructure and binds the private shell stage to the dedicated DevOps subnet and NSG.

## Current Boundary

This stack is intentionally safe by default.
The private shell stage refuses to execute `terraform apply` while runtime Terraform state is still local-file based.
That refusal is deliberate: an ephemeral OCI runner must not guess at or recreate production state from an empty workspace.

Current status:

- explicit git reference selection is wired through `run-release.sh`
- private network placement is provisioned
- release bundle and metadata handoff are provisioned
- commit-derived image tagging is recorded in release metadata, but OCIR publication is not wired through this stack yet
- destructive rollout remains blocked until Terraform backend/state handling is migrated to a reproducible remote strategy

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

## Apply

```bash
cd infrastructure/oci/devops
terraform init
terraform plan
terraform apply
```

The stack now provisions the DevOps project log through OCI Logging, so build runs do not depend on a manual "enable logs" console step.
The stack also provisions the secret-read policy for the external GitHub connection token, while `foundation` provisions the baseline DevOps dynamic group and compartment-scoped runner policy.

## Trigger A Release

Use the helper after the stack has been applied:

```bash
./infrastructure/oci/devops/run-release.sh
```

By default it:

- reads `build_pipeline_id` from Terraform output when possible
- targets the current git `HEAD`
- derives `releaseVersion` from the selected commit short SHA
- leaves `tfBackendMode=local-blocked` so the private shell stage cannot mutate production until backend migration is complete
