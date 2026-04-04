# OCI Deployment Runbook (Container Instance)

This runbook deploys Wort-Werk to OCI using OCIR + Container Instances.

## Scope

Included in this flow:
- single application container
- bundled `assets/` in image
- OCIR push and Container Instance deployment/update

Explicitly out of scope:
- database provisioning/migrations
- Kubernetes/OKE

## Required OCI Resources (Core)

- Dedicated compartment (created by Terraform by default)
- VCN
- Subnet for Container Instance
- NSG or Security List rules
- Internet Gateway (or equivalent egress path)
- OCIR repository
- Container Instance

Optional (later):
- TLS certificate
- DNS record
- OCI monitoring/alarms

## 1) Build and Push the Image to OCIR

Set your OCIR namespace, region and repository:

```bash
OCI_REGION="fra"
OCI_PROFILE="FRANKFURT"
OCIR_NAMESPACE="$(oci os ns get --profile "${OCI_PROFILE}" --query 'data' --raw-output)"
OCI_USERNAME="<oci-username>"
OCIR_REPOSITORY="wort-werk"
IMAGE_TAG="$(git rev-parse --short=12 HEAD)"
IMAGE="${OCI_REGION}.ocir.io/${OCIR_NAMESPACE}/${OCIR_REPOSITORY}:${IMAGE_TAG}"
```

Validate namespace lookup:

```bash
echo "${OCIR_NAMESPACE}"
```

Build from repository root:

```bash
docker buildx build \
  --file ./container/Dockerfile \
  --platform linux/amd64,linux/arm64 \
  --tag "${IMAGE}" \
  --push \
  .
```

Authenticate Docker to OCIR (use OCI auth token as password):

```bash
docker login "${OCI_REGION}.ocir.io" \
  --username "${OCIR_NAMESPACE}/${OCI_USERNAME}" \
  --password-stdin
```

`OCI_PROFILE="FRANKFURT"` is expected to target the Frankfurt region endpoint (`fra`).

If needed, push explicitly:

```bash
docker push "${IMAGE}"
```

## 2) Provision Foundation (Terraform)

Foundation Terraform is in [`infrastructure/oci/foundation`](../infrastructure/oci/foundation).

```bash
cd infrastructure/oci/foundation
# create terraform.tfvars and set tenancy_ocid, parent_compartment_ocid, region and home_region (tenancy home region), plus compartment/network CIDRs and repository name
terraform init
terraform apply
```

This creates compartment, networking and OCIR repository.

Get the tenancy home region (example using profile `FRANKFURT`):

```bash
oci iam region-subscription list \
  --profile "FRANKFURT" \
  --tenancy-id "ocid1.tenancy.oc1..<your-tenancy>" \
  --query 'data[?"is-home-region"==`true`]."region-name" | [0]' \
  --raw-output
```

## 3) Deploy Runtime (Terraform)

Runtime Terraform is in [`infrastructure/oci/runtime`](../infrastructure/oci/runtime).

Fetch foundation outputs:

```bash
FOUNDATION_DIR="infrastructure/oci/foundation"
RUNTIME_DIR="infrastructure/oci/runtime"

COMPARTMENT_OCID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw compartment_ocid)"
SUBNET_ID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw subnet_id)"
NSG_ID="$(terraform -chdir="${FOUNDATION_DIR}" output -raw nsg_id)"
REGISTRY_ENDPOINT="$(terraform -chdir="${FOUNDATION_DIR}" output -raw ocir_registry)"
```

Apply runtime:

```bash
terraform -chdir="${RUNTIME_DIR}" init
terraform -chdir="${RUNTIME_DIR}" apply \
  -var "region=eu-frankfurt-1" \
  -var "tenancy_ocid=ocid1.tenancy.oc1..<your-tenancy>" \
  -var "compartment_ocid=${COMPARTMENT_OCID}" \
  -var "subnet_id=${SUBNET_ID}" \
  -var "nsg_id=${NSG_ID}" \
  -var "image_registry_endpoint=${REGISTRY_ENDPOINT}" \
  -var "image_registry_username=${OCIR_NAMESPACE}/${OCI_USERNAME}" \
  -var "image_registry_password=${OCI_AUTH_TOKEN}" \
  -var "image_repository=${OCI_REGION}.ocir.io/${OCIR_NAMESPACE}/${OCIR_REPOSITORY}" \
  -var "image_tag=${IMAGE_TAG}"
```

Availability Domain is resolved automatically from your tenancy; use `availability_domain_index` if you want a specific AD.

## 4) Ingress and Security Checklist

- Ensure NSG ingress allows TCP `8080` from your test CIDR (start with `0.0.0.0/0` only for initial testing).
- Ensure subnet route table includes `0.0.0.0/0` via Internet Gateway.
- Ensure Container Instance VNIC has public IP assigned for direct IP testing.
- Ensure the identity executing Terraform has permissions to manage OCI network, compartment, OCIR and Container Instance resources.

## 5) Validate Deployment

- Open OCI Console -> Container Instances -> Wort-Werk instance.
- Confirm container state is `RUNNING`.
- Read runtime output `access_url` and open that URL.
- Verify quiz page loads through the Load Balancer endpoint.

No domain is required for initial testing. Load-Balancer HTTP is acceptable until TLS/domain are added.

## 6) Update Strategy (New Image Versions)

For each release:

1. Build and push a new immutable tag (for example git SHA).
2. Re-run runtime apply with the new `image_tag`.
3. Apply runtime stack only.
4. Verify health via browser and Container Instance status.
5. Keep prior image tag for rollback.

Rollback:

1. Re-run runtime apply with previous known-good `image_tag`.
2. Verify Container Instance health.

Scripted release path:

```bash
export OCI_USERNAME="<oci-username>"
export OCI_AUTH_TOKEN="<oci-auth-token>"
export KEEP_IMAGE_COUNT=2
./infrastructure/oci/deploy.sh release
```

To switch to AMD64, set Terraform variable `container_instance_shape` in
`infrastructure/oci/runtime/terraform.tfvars` (for example `CI.Standard.E4.Flex`).

`OCI_PROFILE` defaults to `FRANKFURT` in the script; override only if needed.

`deploy.sh release` aligns with IaC by:
- using foundation Terraform outputs for runtime network wiring
- applying runtime Terraform for the new image
- configuring private OCIR image pull credentials for Container Instance runtime
- pruning only older images beyond a safe retention window (default keep 2)

## 7) Optional TLS + DNS Later

Load Balancer is now part of the runtime stack. When domain/TLS is ready:

1. Attach certificate to HTTPS listener (`443`).
2. Add DNS `A`/`CNAME` record to LB reserved public endpoint.
3. Redirect HTTP to HTTPS if required.
