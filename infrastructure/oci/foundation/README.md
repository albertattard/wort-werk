# OCI Foundation Stack

Foundation Terraform stack for Wort-Werk OCI environment setup.

## Provisions

- dedicated compartment
- VCN
- internet gateway
- NAT gateway for private DevOps runner egress
- service gateway for OCI regional services
- route tables for public load balancer, private runtime, private DevOps, and isolated database paths
- dedicated private subnet for OCI DevOps build and shell stages
- public subnet for Load Balancer
- private subnet for runtime Container Instance
- private subnet reserved for OCI PostgreSQL
- NSGs and ingress/egress rules for runtime, load balancer, database, and DevOps tiers
- OCIR repository
- OCI Vault + key for runtime secrets
- dynamic group for runtime container-instance IAM access
- dynamic group and baseline IAM policy for OCI DevOps build/deploy runners
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
3. create or rotate the runtime TLS Vault secrets through `../runtime/set-tls-secrets.sh`
4. apply `../runtime` for the one-time backend migration only, or apply `../devops` to provision the normal OCI DevOps release path

Create the DB password secrets with OCI CLI by following:
- [`../data/README.md`](../data/README.md)

Recommended command:

```bash
../data/set-db-secrets.sh
```

Create the runtime TLS Vault secrets by following:
- [`../runtime/README.md`](../runtime/README.md)

Recommended command:

```bash
../runtime/set-tls-secrets.sh
```

## Key Outputs

- `region`
- `tenancy_ocid`
- `compartment_ocid`
- `subnet_id`
- `runtime_subnet_id`
- `load_balancer_subnet_id`
- `database_subnet_id`
- `devops_subnet_id`
- `nsg_id`
- `database_nsg_id`
- `load_balancer_nsg_id`
- `devops_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `lb_listener_port`
- `https_listener_port`
- `management_port`
- `ocir_namespace`
- `ocir_repository_name`
- `ocir_repository_id`
- `image_repository`
- `terraform_state_bucket_name`
- `vault_id`
- `vault_key_id`
- `runtime_dynamic_group_name`
- `devops_dynamic_group_name`

## Network Boundaries

- The Load Balancer NSG accepts public ingress only on `80` and `443`.
- The runtime NSG accepts the application port and the internal management port only from the Load Balancer NSG.
- The runtime subnet is private and prohibits public IP assignment on runtime VNICs.
- The DevOps subnet is private and exists only for OCI-managed build and shell stages that need private service or database reachability.
- The runtime route table provides private access to OCI regional services through the service gateway.
- The DevOps route table combines OCI service-gateway access with NAT-backed outbound internet egress so private runners can fetch source from external SCM providers without public IPs.
- The DevOps NSG can reach PostgreSQL, OCI regional services, and outbound HTTPS, but does not receive public ingress.
- The management port exists for Spring Actuator readiness checks and is not exposed through a public listener.
- Foundation also owns the baseline DevOps runner IAM boundary: a dedicated dynamic group plus least-privilege compartment-scoped policies for `devops-family`, private VNIC attachments, release-handoff bucket access, and shell-stage container instances.
- That baseline IAM boundary also needs the runtime ingress permissions required by OCI-resident rollout: load balancer management plus reserved public IP use, scoped to the Wort-Werk compartment rather than broader tenancy access.
