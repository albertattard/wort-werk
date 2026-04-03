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

- Compartment (existing or dedicated)
- VCN
- Subnet for Container Instance
- NSG or Security List rules
- Internet Gateway (or equivalent egress path)
- OCIR repository
- Container Instance
- IAM policies for push/deploy operations

Optional (later):
- OCI Load Balancer
- TLS certificate
- DNS record
- OCI monitoring/alarms

## 1) Build and Push the Image to OCIR

Set your OCIR namespace, region and repository:

```bash
OCI_REGION="fra"
OCIR_NAMESPACE="<your-namespace>"
OCIR_REPOSITORY="wort-werk"
IMAGE_TAG="$(git rev-parse --short HEAD)"
IMAGE="${OCI_REGION}.ocir.io/${OCIR_NAMESPACE}/${OCIR_REPOSITORY}:${IMAGE_TAG}"
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
  --username "${OCIR_NAMESPACE}/<oci-username>" \
  --password-stdin
```

If needed, push explicitly:

```bash
docker push "${IMAGE}"
```

## 2) Provision Core Infrastructure (Terraform)

Terraform definitions are in [`infrastructure/oci/terraform`](../infrastructure/oci/terraform).

```bash
cd infrastructure/oci/terraform
cp terraform.tfvars.example terraform.tfvars
# set compartment, availability domain, image_url, region and ingress CIDR
terraform init
terraform apply
```

This creates networking, OCIR repository and Container Instance prerequisites plus the Container Instance itself.

## 3) Ingress and Security Checklist

- Ensure NSG ingress allows TCP `8080` from your test CIDR (start with `0.0.0.0/0` only for initial testing).
- Ensure subnet route table includes `0.0.0.0/0` via Internet Gateway.
- Ensure Container Instance VNIC has public IP assigned for direct IP testing.
- Ensure IAM groups used for push/deploy have required policies.

## 4) Validate Deployment

- Open OCI Console -> Container Instances -> Wort-Werk instance.
- Confirm container state is `RUNNING`.
- Open `http://<public-ip>:8080` and verify quiz page loads.

No domain is required for initial testing. Public-IP HTTP is acceptable until TLS/domain are added.

## 5) Update Strategy (New Image Versions)

For each release:

1. Build and push a new immutable tag (for example git SHA).
2. Update `image_url` in Terraform variables to the new tag.
3. Run `terraform apply`.
4. Verify health via browser and Container Instance status.
5. Keep prior image tag for rollback.

Rollback:

1. Restore previous known-good image tag in Terraform variables.
2. Re-run `terraform apply`.

## 6) Optional Load Balancer + TLS Later

When domain/TLS is ready:

1. Provision OCI Load Balancer in public subnet.
2. Point backend set to Container Instance private endpoint/port `8080`.
3. Attach certificate to HTTPS listener (`443`).
4. Add DNS `A`/`CNAME` record to LB public endpoint.
5. Restrict direct Container Instance ingress to LB subnet only.
