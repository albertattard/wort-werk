# OCI Terraform (TASK-007)

Terraform definitions for deploying Wort-Werk on OCI Container Instances.

## Scope

Core resources included:
- compartment (existing by default, optional creation switch)
- VCN
- public subnet for Container Instance
- NSG rules (ingress app port + egress all)
- Internet Gateway + route table
- OCIR repository
- Container Instance
- optional IAM policy statements for push/deploy groups

Optional resources intentionally excluded from this stack:
- OCI Load Balancer
- TLS certificate management
- DNS records
- OCI monitoring/alarms

Non-goals:
- database resources
- Kubernetes/OKE

## Prerequisites

- Terraform 1.8+
- OCI credentials configured (for example via `~/.oci/config`)
- Built/pushed container image in OCIR

## Usage

```bash
cd infrastructure/oci/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with real OCIDs and image URL

terraform init
terraform plan
terraform apply
```

For a first public test without domain/TLS, keep port `8080` reachable and use the public IP of the Container Instance.

## Notes

- `create_compartment=false` expects `compartment_ocid` to be provided.
- `create_compartment=true` creates a dedicated compartment under `tenancy_ocid`.
- `create_iam_policy=true` writes policy in tenancy root and requires adequate IAM permissions.
