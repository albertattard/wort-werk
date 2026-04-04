# OCI IaC Layout

Wort-Werk OCI Terraform is split into two stacks.

- `foundation/`: one-time or infrequent environment provisioning
- `runtime/`: frequent application rollout by image tag

Apply order:
1. foundation
2. runtime

## Helper Scripts

- `./infrastructure/oci/deploy.sh all`: apply foundation then runtime (default).
- `./infrastructure/oci/deploy.sh foundation`: apply foundation only.
- `./infrastructure/oci/deploy.sh runtime`: apply runtime only.
- `./infrastructure/oci/deploy.sh release`: build, push and deploy runtime with a new image tag.

- `./infrastructure/oci/destroy.sh all`: destroy runtime then foundation (default).
- `./infrastructure/oci/destroy.sh runtime`: destroy runtime only.
- `./infrastructure/oci/destroy.sh foundation`: destroy foundation only.

The deploy script writes `runtime/foundation.auto.tfvars` from foundation outputs:
- `region`
- `tenancy_ocid`
- `compartment_ocid`
- `subnet_id`
- `nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `image_repository`
- `image_registry_endpoint`
- `app_port`
- `lb_listener_port`
- `load_balancer_min_bandwidth_mbps`
- `load_balancer_max_bandwidth_mbps`

Release mode requires:
- `OCI_USERNAME`
- `OCI_AUTH_TOKEN`

Optional release variables:
- `OCI_PROFILE` (default `FRANKFURT`)
- `IMAGE_TAG` (default current git short SHA)
- `OCIR_REPOSITORY` (optional fallback override for cleanup lookup)
- `DOCKER_PLATFORM` (default `linux/amd64,linux/arm64`)
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

- Terraform in this repository does not manage Let’s Encrypt certificate/private key material.
- TLS certificate issuance and renewal are manual operational steps documented in [`container/OCI-DEPLOYMENT.md`](../../container/OCI-DEPLOYMENT.md).
- This avoids storing private keys in Terraform state.
