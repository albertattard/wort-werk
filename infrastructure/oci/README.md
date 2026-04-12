# OCI IaC Layout

Wort-Werk OCI Terraform is split into three stacks.

- `foundation/`: durable shared environment provisioning
- `data/`: managed PostgreSQL and DB-secret-dependent policy wiring
- `runtime/`: application rollout by image tag

Apply order:
1. foundation
2. create or rotate DB secrets in OCI Vault
3. data
4. runtime or release

## Set the DB Credentials

After `foundation` has been applied, create the PostgreSQL admin password secret and runtime DB password secret in OCI Vault, then write their OCIDs into `infrastructure/oci/data/terraform.tfvars`.

Copy-pasteable commands are documented in:
- [`./data/README.md`](./data/README.md)

Recommended command:

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/data/set-db-secrets.sh
```

While `runtime_db_username` still defaults to `wortwerk_admin`, `set-db-secrets.sh` reuses the PostgreSQL admin password for the runtime secret and rejects mismatched values.

## Helper Scripts

- `./infrastructure/oci/deploy.sh all`: apply foundation, data, then runtime.
- `./infrastructure/oci/deploy.sh foundation`: apply foundation only.
- `./infrastructure/oci/deploy.sh data`: apply data only.
- `./infrastructure/oci/deploy.sh runtime`: apply runtime only.
- `./infrastructure/oci/deploy.sh release`: run `./mvnw clean verify` (local single-platform image), then publish multi-arch image and deploy runtime with a new image tag.
- `./infrastructure/oci/deploy.sh rollout`: repeatable full rollout (`foundation`, `data`, then `release`).
  - preflight: fails if git has pending changes outside `assets/images/new`
  - override: set `ALLOW_DIRTY_ROLLOUT=true` for intentional exception runs
- `./tools/rollout`: sources `~/.oci/oci.secrets.env`, preserves explicit `VERIFY_DB_USERNAME` / `VERIFY_DB_PASSWORD` values when present, generates ephemeral local ones when missing, and runs `deploy.sh rollout` from repo root.

Runtime `image_tag` behavior:
- `runtime` resolves tag in this order: `IMAGE_TAG` env var, existing `runtime/release.auto.tfvars:image_tag`, current runtime Terraform output `deployed_image_url` tag.
- If no previous runtime deployment exists and `IMAGE_TAG` is not provided, runtime apply fails with an actionable message.

- `./infrastructure/oci/destroy.sh all`: destroy runtime, data, then foundation.
- `./infrastructure/oci/destroy.sh runtime`: destroy runtime only.
- `./infrastructure/oci/destroy.sh data`: destroy data only.
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
- `subnet_id`
- `nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `load_balancer_public_ip`
- `image_repository`
- `image_registry_endpoint`
- `app_port`
- `lb_listener_port`
- `https_listener_port`
- `load_balancer_min_bandwidth_mbps`
- `load_balancer_max_bandwidth_mbps`
- `runtime_db_url`
- `runtime_db_username`
- `runtime_db_password_secret_ocid`
- `runtime_db_ssl_root_cert_base64`

Release mode requires:
- `OCI_USERNAME`
- `OCI_AUTH_TOKEN`

Optional release variables:
- `OCI_PROFILE` (default `FRANKFURT`)
- `IMAGE_TAG` (default current git short SHA)
- `IMAGE_TAG` is also honored by `runtime`/`rollout` when you want to pin runtime apply to a specific tag.
- `VERIFY_IMAGE_TAG` (default `<repo-name>:verify-release`; local image tag used by `clean verify`)
- `DOCKER_PLATFORM` (default `linux/amd64,linux/arm64`; release publish platforms)
- `OCIR_REPOSITORY` (optional fallback override for cleanup lookup)
- `PRUNE_OLD_IMAGES` (`true` by default)
- `KEEP_IMAGE_COUNT` (`2` by default; minimum enforced to 2)

Cleanup behavior:
- release cleanup uses foundation output `ocir_repository_id` when available
- if repository resolution fails, deployment still succeeds and cleanup is skipped with a warning

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

## Database Security Model

- OCI Database with PostgreSQL is provisioned in the `data` stack on a private subnet exposed by `foundation`.
- The database NSG accepts PostgreSQL traffic only from the application NSG.
- Runtime DB passwords are stored in OCI Vault.
- The container instance reads the runtime DB password from OCI Vault by using OCI resource principal.
- Foundation provisions Vault, key, dynamic group, and shared network boundaries; secret values themselves must be created or rotated outside Terraform.
- Data provisions the managed PostgreSQL system and the runtime secret-read policy scoped to the configured runtime secret.

## Naming Convention

- Fixed Wort-Werk resource identity is centralized in Terraform `locals`.
- Deployment-specific or operator-chosen values remain in `variables.tf`.
- Avoid introducing variables for names that are effectively part of the application's stable OCI identity.
