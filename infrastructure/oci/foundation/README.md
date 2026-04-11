# OCI Foundation Stack

Foundation Terraform stack for Wort-Werk OCI environment setup.

## Provisions

- dedicated compartment
- VCN
- internet gateway
- route tables
- subnet for Container Instance
- private subnet reserved for OCI PostgreSQL
- NSGs and ingress/egress rules for container, load balancer, and database tiers
- OCIR repository
- OCI Vault + key for runtime secrets
- dynamic group for container-instance secret reads
- reserved public IP for Load Balancer

Key rotation note:
- automatic KMS key rotation is disabled
- the current setup uses the default virtual vault, which does not support automatic key rotation
- if you later require automatic key rotation, you need a vault type that supports it and should revisit this design explicitly

## Does Not Provision

- OCI Database with PostgreSQL
- Container Instance runtime
- load balancer, TLS, DNS

## Usage

```bash
cd infrastructure/oci/foundation
terraform init
terraform plan
terraform apply
```

Compartment operations run against `home_region` (OCI tenancy home region).
The Wort-Werk compartment is created under `parent_compartment_ocid`.

After foundation apply:
1. create or rotate the required Vault secrets outside Terraform
2. apply `../data`
3. apply `../runtime` or run `../deploy.sh release`

Create the DB password secrets with OCI CLI by following:
- [`../data/README.md`](../data/README.md)

Recommended command:

```bash
OCI_PROFILE="FRANKFURT" ../data/set-db-secrets.sh
```

## Key Outputs

- `region`
- `tenancy_ocid`
- `compartment_ocid`
- `subnet_id`
- `database_subnet_id`
- `nsg_id`
- `database_nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `lb_listener_port`
- `https_listener_port`
- `ocir_namespace`
- `ocir_repository_name`
- `ocir_repository_id`
- `image_repository`
- `vault_id`
- `vault_key_id`
- `runtime_dynamic_group_name`
