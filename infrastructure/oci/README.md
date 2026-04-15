# OCI IaC Layout

Wort-Werk OCI Terraform is split into three stacks.

- `foundation/`: durable shared environment provisioning
- `data/`: managed PostgreSQL and DB-secret-dependent policy wiring
- `runtime/`: application rollout by image tag

An in-progress fourth stack now exists for the OCI-native release control plane:

- `devops/`: OCI DevOps managed build/deploy scaffolding for private release execution

Apply order:
1. foundation
2. create or rotate DB secrets in OCI Vault
3. data
4. optionally create the GitHub DevOps connection secret and OCIR push secret in OCI Vault, then apply `devops/`
5. bootstrap the dedicated runtime DB role from a host that can reach the private PostgreSQL endpoint
6. runtime

## Set the DB Credentials

After `foundation` has been applied, create the PostgreSQL admin password secret and runtime DB password secret in OCI Vault, then write their OCIDs into `infrastructure/oci/data/terraform.tfvars`.

Copy-pasteable commands are documented in:
- [`./data/README.md`](./data/README.md)

Recommended command:

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/data/set-db-secrets.sh
```

The runtime secret is always independent from the PostgreSQL administrator secret. The default runtime DB username is `wortwerk_app`.

After `data` has been applied, bootstrap the dedicated runtime role and grants from a host that can resolve and reach the private PostgreSQL endpoint:

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/deploy.sh db-role
```

## Helper Scripts

- `./infrastructure/oci/deploy.sh all`: apply foundation, data, then runtime.
- `./infrastructure/oci/deploy.sh foundation`: apply foundation only.
- `./infrastructure/oci/deploy.sh devops`: apply the OCI DevOps release-runner stack after `foundation` and `data` outputs exist.
- `./infrastructure/oci/deploy.sh data`: apply data only.
- `./infrastructure/oci/deploy.sh db-role`: bootstrap or rotate the dedicated runtime DB role from a host with private DB connectivity.
- `./infrastructure/oci/deploy.sh runtime`: reserved for the one-time backend migration or OCI DevOps-driven runtime apply.
- `./infrastructure/oci/devops/run-release.sh`: trigger the OCI DevOps build/deploy pipeline from an explicit git reference.
- Run `./infrastructure/oci/deploy.sh db-role` after changing administrator or runtime DB passwords so PostgreSQL stays in sync with OCI Vault before `runtime` or any OCI DevOps release.

## One-Time Runtime State Migration

Before the first OCI DevOps-managed rollout, migrate the existing local runtime Terraform state into the OCI backend bucket created by `foundation`:

```bash
RUNTIME_BACKEND_MIGRATE=true ./infrastructure/oci/deploy.sh runtime
```

This migration is intentionally explicit. `deploy.sh runtime` refuses to auto-migrate a detected local `runtime/terraform.tfstate` unless `RUNTIME_BACKEND_MIGRATE=true` is set.
After that migration, `deploy.sh runtime` is expected to run only inside OCI DevOps (`OCI_CLI_AUTH=resource_principal`).

Runtime `image_tag` behavior:
- `runtime` resolves tag in this order: `IMAGE_TAG` env var, existing `runtime/release.auto.tfvars:image_tag`, current runtime Terraform output `deployed_image_url` tag.
- If no previous runtime deployment exists and `IMAGE_TAG` is not provided, runtime apply fails with an actionable message.

- `./infrastructure/oci/destroy.sh all`: destroy runtime, data, then foundation.
- `./infrastructure/oci/destroy.sh runtime`: destroy runtime only.
- `./infrastructure/oci/destroy.sh data`: destroy data only.
- `./infrastructure/oci/destroy.sh devops`: destroy the OCI DevOps release-runner stack only.
- `./infrastructure/oci/destroy.sh foundation`: destroy foundation only.

The deploy script writes `data/foundation.auto.tfvars` from foundation outputs:
- `region`
- `home_region`
- `compartment_ocid`
- `database_subnet_id`
- `database_nsg_id`
- `runtime_dynamic_group_name`

The deploy script writes `runtime/foundation.auto.tfvars` from foundation and data outputs:
- `region`
- `tenancy_ocid`
- `compartment_ocid`
- `runtime_subnet_id`
- `load_balancer_subnet_id`
- `nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `image_repository`
- `image_registry_endpoint`
- `app_port`
- `management_port`
- `lb_listener_port`
- `https_listener_port`
- `load_balancer_min_bandwidth_mbps`
- `load_balancer_max_bandwidth_mbps`
- `runtime_db_url`
- `runtime_db_username`
- `runtime_db_password_secret_ocid`
- `runtime_db_ssl_root_cert_base64`

The deploy script writes `devops/foundation.auto.tfvars` from foundation outputs:
- `region`
- `home_region`
- `compartment_ocid`
- `devops_subnet_id`
- `devops_nsg_id`
- `devops_dynamic_group_name`
- `image_repository`
- `image_registry_endpoint`
- `runtime_state_bucket_name`
- `runtime_subnet_id`
- `load_balancer_subnet_id`
- `nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `app_port`
- `management_port`
- `lb_listener_port`
- `https_listener_port`
- `load_balancer_min_bandwidth_mbps`
- `load_balancer_max_bandwidth_mbps`
- `runtime_db_url`
- `runtime_db_username`
- `runtime_db_password_secret_ocid`
- `postgresql_db_system_id`
- `postgresql_admin_username`
- `postgresql_admin_password_secret_ocid`
- `postgresql_host`
- `postgresql_port`
- `postgresql_database_name`

Runtime apply still honors:
- `IMAGE_TAG` when you want to pin runtime apply to a specific tag.

DevOps stack requires:
- `github_connection_token_secret_ocid` in `infrastructure/oci/devops/terraform.tfvars`
- `image_registry_username` in `infrastructure/oci/devops/terraform.tfvars`
- `image_registry_password_secret_ocid` in `infrastructure/oci/devops/terraform.tfvars`

`release.auto.tfvars` is generated with:
- `image_tag`
- `image_registry_username`
- `image_registry_password`

To change runtime shape, set Terraform variable `container_instance_shape` in:
- `infrastructure/oci/runtime/terraform.tfvars`
- or another `*.auto.tfvars` file in `infrastructure/oci/runtime/`

## TLS Ownership

- Terraform runtime manages load balancer certificate and HTTPS listener resources.
- Certificate issuance and renewal remain manual (Let's Encrypt DNS challenge), then certificate files are copied to `infrastructure/oci/runtime/tls/wortwerk.xyz/`.
- Runtime Terraform reads these files during `terraform apply`.

## Health Check Design

- OCI runtime injects `MANAGEMENT_SERVER_PORT` so Spring Actuator listens on a dedicated internal port.
- The Load Balancer health checker targets `/actuator/health/readiness` on that management port.
- Foundation NSGs allow the management port only from the Load Balancer NSG; no public listener is created for it.
- Readiness includes database health, so OCI only routes traffic when the app and PostgreSQL dependency are both ready.

## Runtime Network Design

- The Load Balancer stays on the public subnet with the reserved public IP.
- The Wort-Werk container instance runs on a dedicated private runtime subnet and does not receive a public IP.
- OCI DevOps private build and shell stages run on a separate private subnet and NSG so release execution has a narrower trust boundary than the runtime tier.
- Foundation provides a service-gateway path for OCI regional services so runtime startup dependencies such as Vault-backed secret reads remain available without public internet exposure.
- The DevOps subnet may require outbound HTTPS to external SCM providers; when that is needed, the path must be isolated to the DevOps subnet through NAT-backed egress rather than copied onto the runtime subnet.
- Public traffic reaches the backend only through the Load Balancer; the application container is addressed privately inside the VCN.

## Database Security Model

- OCI Database with PostgreSQL is provisioned in the `data` stack on a private subnet exposed by `foundation`.
- The database NSG accepts PostgreSQL traffic only from the application NSG.
- Runtime DB passwords are stored in OCI Vault.
- Runtime uses the dedicated non-admin role `wortwerk_app` by default.
- The container instance reads the runtime DB password from OCI Vault by using OCI resource principal.
- Foundation provisions Vault, key, dynamic group, and shared network boundaries; secret values themselves must be created or rotated outside Terraform.
- Foundation also provisions the DevOps runner dynamic group plus baseline least-privilege runner policies for `devops-family`, private-network attachment, release-handoff storage access, and shell-stage container instances.
- That DevOps runner policy also needs `read postgres-db-systems` because the build resolves the PostgreSQL CA certificate from OCI connection details rather than from a passed build argument.
- Data provisions the managed PostgreSQL system and the runtime secret-read policy scoped to the configured runtime secret.
- DevOps provisions least-privilege secret-read policy statements scoped to the configured GitHub PAT, OCIR push secret, runtime DB password secret, and PostgreSQL administrator password secret.
- The privileged role bootstrap path lives in `data/bootstrap-runtime-db-role.sh` and must run from a machine with private connectivity to the managed PostgreSQL endpoint.
- The DevOps shell stage is provisioned on private OCI networking for this bootstrap path and must consume OCI-managed release metadata instead of laptop-local `foundation` / `data` state files.
- The DevOps shell stage must also provision the PostgreSQL client tooling required by `data/bootstrap-runtime-db-role.sh` because the managed shell image does not guarantee `psql` out of the box.
- The OCI DevOps build stage is the intended normal path for verification and runtime image publication.

## Naming Convention

- Fixed Wort-Werk resource identity is centralized in Terraform `locals`.
- Deployment-specific or operator-chosen values remain in `variables.tf`.
- Avoid introducing variables for names that are effectively part of the application's stable OCI identity.
