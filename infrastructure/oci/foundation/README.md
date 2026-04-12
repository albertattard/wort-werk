# OCI Foundation Stack

Foundation Terraform stack for Wort-Werk OCI environment setup.

## Provisions

- dedicated compartment
- VCN
- internet gateway
- service gateway for OCI regional services
- route tables for public load balancer, private runtime, and private database paths
- public subnet for Load Balancer
- private subnet for Container Instance runtime
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
- `runtime_subnet_id`
- `load_balancer_subnet_id`
- `database_subnet_id`
- `nsg_id`
- `database_nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `lb_listener_port`
- `https_listener_port`
- `management_port`
- `ocir_namespace`
- `ocir_repository_name`
- `ocir_repository_id`
- `image_repository`
- `vault_id`
- `vault_key_id`
- `runtime_dynamic_group_name`

## Network Boundaries

- The Load Balancer NSG accepts public ingress only on `80` and `443`.
- The container NSG accepts the application port and the internal management port only from the Load Balancer NSG.
- The runtime subnet is private and prohibits public IP assignment on runtime VNICs.
- The runtime route table provides private access to OCI regional services through the service gateway.
- The management port exists for Spring Actuator readiness checks and is not exposed through a public listener.
