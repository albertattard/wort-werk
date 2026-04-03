# OCI Runtime Stack

Runtime Terraform stack for Wort-Werk Container Instance rollout.

## Provisions

- OCI Container Instance only

## Depends On

Outputs from `infrastructure/oci/foundation`:
- `compartment_ocid`
- `subnet_id`
- `nsg_id`

## Usage

```bash
cd infrastructure/oci/runtime
cp terraform.tfvars.example terraform.tfvars
# set foundation outputs and image repository/tag
terraform init
terraform plan
terraform apply
```

Use immutable image tags (git commit hash recommended) for repeatable rollouts and rollback.
