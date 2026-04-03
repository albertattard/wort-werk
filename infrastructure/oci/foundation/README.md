# OCI Foundation Stack

Foundation Terraform stack for Wort-Werk OCI environment setup.

## Provisions

- dedicated compartment
- VCN
- internet gateway
- route table
- NSG + ingress/egress rules
- subnet for Container Instance
- OCIR repository

## Does Not Provision

- Container Instance runtime
- database resources
- Kubernetes/OKE
- load balancer, TLS, DNS

## Usage

```bash
cd infrastructure/oci/foundation
cp terraform.tfvars.example terraform.tfvars
# edit with real tenancy OCID and region
terraform init
terraform plan
terraform apply
```

## Key Outputs

- `compartment_ocid`
- `subnet_id`
- `nsg_id`
- `ocir_namespace`
- `ocir_repository_name`
