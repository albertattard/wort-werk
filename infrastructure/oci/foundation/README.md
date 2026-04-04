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
- reserved public IP for Load Balancer
- NSG for Load Balancer ingress/egress

## Does Not Provision

- Container Instance runtime
- database resources
- Kubernetes/OKE
- load balancer, TLS, DNS

## Usage

```bash
cd infrastructure/oci/foundation
# create terraform.tfvars with real tenancy OCID, parent compartment OCID, workload region and home region
terraform init
terraform plan
terraform apply
```

Compartment operations run against `home_region` (OCI tenancy home region).
The Wort-Werk compartment is created under `parent_compartment_ocid`.

## Key Outputs

- `region`
- `tenancy_ocid`
- `compartment_ocid`
- `subnet_id`
- `nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `ocir_namespace`
- `ocir_repository_name`
- `ocir_repository_id`
- `image_repository`
