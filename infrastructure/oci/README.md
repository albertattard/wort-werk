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
- `compartment_ocid`
- `subnet_id`
- `nsg_id`

Release mode requires:
- `OCI_PROFILE`
- `OCI_USERNAME`
- `OCI_AUTH_TOKEN`

Optional release variables:
- `OCI_REGION` (default `fra`)
- `IMAGE_TAG` (default current git short SHA)
- `OCIR_NAMESPACE` (auto-resolved if omitted)
- `OCIR_REPOSITORY` (default from foundation output)
- `DOCKER_PLATFORM` (default `linux/amd64,linux/arm64`)
- `PRUNE_OLD_IMAGES` (`true` by default)
- `KEEP_IMAGE_COUNT` (`2` by default; minimum enforced to 2)
