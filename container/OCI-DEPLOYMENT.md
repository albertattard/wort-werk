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

Authenticate Docker to OCIR (use OCI auth token as password):

```bash
docker login "${OCI_REGION}.ocir.io" \
  --username "${OCIR_NAMESPACE}/${OCI_USERNAME}" \
  --password-stdin
```

Build from repository root with a full Docker Buildx installation:

```bash
docker buildx build \
  --file ./container/Dockerfile \
  --platform linux/amd64,linux/arm64 \
  --tag "${IMAGE}" \
  --push \
  .
```

`OCI_PROFILE="FRANKFURT"` is expected to target the Frankfurt region endpoint (`fra`).

On OCI-managed runners, the available build surface may be Podman-compatible rather than full Docker Buildx. In that case the repository release automation may fall back to manifest-based publication instead of inline `--push`.

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

- Ensure container NSG ingress allows TCP `8080` from Load Balancer NSG.
- Ensure load balancer NSG ingress allows TCP `80` and `443` from your test CIDR (start with `0.0.0.0/0` only for initial testing).
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

Runtime deploys reduce `502` during replacement by:
- creating replacement Container Instance before destroying previous one
- creating replacement LB backend before removing previous one
- using HTTP readiness health checks (`/` returns `200`) instead of TCP-only checks

Residual risk:
- with single-instance architecture, transient disruption is reduced but not mathematically eliminated

## 7) TLS with Let's Encrypt (Manual DNS Challenge)

Use this when you want HTTPS for `wortwerk.xyz` without buying a certificate.

Important:
- Certificate issuance is still manual (Let's Encrypt DNS challenge).
- Certificate installation is managed by Terraform using project-local PEM files.

### 7.1 Point DNS to OCI Load Balancer

Get your stable Load Balancer IP from runtime output:

```bash
terraform -chdir="infrastructure/oci/runtime" output -raw public_ip
```

Create DNS records at your registrar/DNS provider:
- `A` record: `wortwerk.xyz` -> `<load-balancer-public-ip>`
- `A` record: `www.wortwerk.xyz` -> `<load-balancer-public-ip>` (optional but recommended)

### 7.2 Issue Certificate (manual, from your laptop)

Install Certbot locally (for example with Homebrew on macOS):

```bash
brew install certbot
```

Prepare writable Certbot directories (avoids root/system path permission issues):

```bash
mkdir -p "${HOME}/.certbot/config" "${HOME}/.certbot/work" "${HOME}/.certbot/logs"
```

Run manual DNS challenge issuance:

```bash
certbot certonly \
  --manual \
  --preferred-challenges dns \
  --server https://acme-v02.api.letsencrypt.org/directory \
  --key-type rsa \
  --cert-name wortwerk.xyz \
  -d wortwerk.xyz \
  -d www.wortwerk.xyz \
  --agree-tos \
  -m <your-email> \
  --config-dir "${HOME}/.certbot/config" \
  --work-dir "${HOME}/.certbot/work" \
  --logs-dir "${HOME}/.certbot/logs"
```

Certbot will print one or more TXT records to create (for example under `_acme-challenge.wortwerk.xyz`).  
Create exactly what Certbot prints, then verify propagation before pressing Enter:

```bash
dig +short TXT _acme-challenge.wortwerk.xyz
dig +short TXT _acme-challenge.www.wortwerk.xyz
```

When issuance succeeds, certificate files are under:
- `${HOME}/.certbot/config/live/wortwerk.xyz/fullchain.pem`
- `${HOME}/.certbot/config/live/wortwerk.xyz/privkey.pem`

### 7.3 Copy Certificate Files Into Runtime Terraform Directory

```bash
mkdir -p infrastructure/oci/runtime/tls/wortwerk.xyz
cp "${HOME}/.certbot/config/live/wortwerk.xyz/fullchain.pem" infrastructure/oci/runtime/tls/wortwerk.xyz/fullchain.pem
cp "${HOME}/.certbot/config/live/wortwerk.xyz/privkey.pem" infrastructure/oci/runtime/tls/wortwerk.xyz/privkey.pem
```

### 7.4 Apply Runtime Terraform for HTTPS + Redirect

```bash
terraform -chdir="infrastructure/oci/runtime" apply \
  -var "tls_certificate_name=wortwerk_xyz_$(date +%Y%m%d)" \
  -var "tls_public_certificate_path=tls/wortwerk.xyz/fullchain.pem" \
  -var "tls_private_key_path=tls/wortwerk.xyz/privkey.pem" \
  -var "tls_redirect_host=wortwerk.xyz"
```

This runtime apply performs all TLS infrastructure changes:
- uploads/updates OCI LB certificate bundle
- creates/updates HTTPS listener on `443`
- configures HTTP (`80`) to HTTPS redirect (`301`)

## 8) Manual Renewal Every 90 Days

Let’s Encrypt certificates are valid for 90 days. With manual DNS challenge, renew before expiry (recommended at day ~60).

Renewal procedure:

1. Re-run the same `certbot certonly --manual ...` command in section 7.2.
2. Create fresh `_acme-challenge` TXT record(s) shown by Certbot.
3. Wait for DNS propagation and complete challenge.
4. Copy the renewed `fullchain.pem` + `privkey.pem` into `infrastructure/oci/runtime/tls/wortwerk.xyz/`.
5. Re-run runtime apply with a new `tls_certificate_name` value.
6. Validate HTTPS and expiry:

```bash
curl -I https://wortwerk.xyz
openssl s_client -connect wortwerk.xyz:443 -servername wortwerk.xyz 2>/dev/null | openssl x509 -noout -dates -issuer -subject
```

Operational recommendation:
- set a recurring calendar reminder every 60 days named `Renew wortwerk.xyz Let's Encrypt certificate`.
