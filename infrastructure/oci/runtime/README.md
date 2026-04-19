# OCI Runtime Stack

Runtime Terraform stack for Wort-Werk Container Instance rollout.

## Provisions

- OCI Container Instance
- OCI Load Balancer with stable reserved public IP endpoint
- OCI Load Balancer certificate (from OCI Vault PEM secrets)
- HTTPS listener and HTTP to HTTPS redirect
- runtime DB environment wiring for OCI PostgreSQL
- private runtime placement behind the public Load Balancer

## Depends On

Outputs from `infrastructure/oci/foundation`:
- `region`
- `tenancy_ocid`
- `compartment_ocid`
- `runtime_subnet_id`
- `load_balancer_subnet_id`
- `nsg_id`
- `load_balancer_nsg_id`
- `load_balancer_public_ip_id`
- `image_repository`
- `image_registry_endpoint`
- `management_port`

Outputs from `infrastructure/oci/data`:
- `runtime_db_url`
- `runtime_db_username`
- `runtime_db_password_secret_ocid`
- `runtime_db_ssl_root_cert_base64`

## Usage

```bash
cd infrastructure/oci/runtime
terraform init
terraform plan
terraform apply
```

Before runtime apply, store the TLS material in OCI Vault and write the secret OCIDs into `infrastructure/oci/runtime/terraform.tfvars`:

```bash
./infrastructure/oci/runtime/set-tls-secrets.sh
```

This example relies on the script default OCI CLI profile name `FRANKFURT`; set `OCI_PROFILE=...` only when you need a different profile.

Required Vault-backed TLS inputs:
- `tls_public_certificate_secret_ocid`
- `tls_private_key_secret_ocid`

Optional Vault-backed TLS input:
- `tls_ca_certificate_secret_ocid`

The helper script updates these keys in `runtime/terraform.tfvars` without overwriting unrelated runtime settings.

## Deploy 502 Mitigation

Runtime applies use two mechanisms to reduce transient `502` during image replacement:

- Container Instance resource uses `create_before_destroy`.
- Load Balancer backend resource uses `create_before_destroy`.

Backend health checks use Spring Actuator readiness (`/actuator/health/readiness` expecting `200`) instead of TCP-only socket checks.
This reduces premature routing, while keeping health probing off learner-facing routes.

Runtime injects `MANAGEMENT_SERVER_PORT`, so Spring Actuator can listen on a dedicated internal port.
The Load Balancer probes that port directly, but runtime does not add any public listener for it.

Runtime networking uses separate subnet roles:
- the Load Balancer stays on the public subnet
- the container instance runs on the private runtime subnet without a public IP
- Vault-dependent startup traffic uses the OCI service gateway path from foundation

Use immutable image tags (git commit hash recommended) for repeatable rollouts and rollback.
Production uses `CI.Standard.E4.Flex` by default.
Use `container_instance_shape` to switch between Arm and AMD64 when needed.
Examples:
- `CI.Standard.E4.Flex` (AMD64)
- `CI.Standard.A1.Flex` (Arm64, opt-in only while regional capacity remains variable)

When using `../deploy.sh runtime`, runtime inputs are generated from `foundation` and `data` outputs automatically, unless OCI DevOps provides them explicitly through exported release metadata.
Laptop-local `../deploy.sh runtime` is reserved for the one-time backend migration only; production runtime mutation is expected to happen from OCI DevOps.
Normal production image publication is expected to run through `../devops/run-release.sh`, not through a laptop-local release helper.
That same OCI DevOps rollout now expects TLS certificate material to already exist in OCI Vault rather than in repository-local PEM files.
If a pre-DevOps runtime environment has live load balancer resources that are missing from remote state, `../deploy.sh runtime` now imports those resources into the remote backend before the normal apply continues.

Runtime injects:
- `WORTWERK_DB_URL`
- `WORTWERK_DB_USERNAME`
- `WORTWERK_DB_PASSWORD_SECRET_OCID`
- `WORTWERK_DB_SSL_ROOT_CERT_BASE64`
- `MANAGEMENT_SERVER_PORT`

The application then:
- fetches the DB password from OCI Vault via container-instance resource principal
- materializes the PostgreSQL CA certificate locally at startup
- verifies PostgreSQL TLS with `sslmode=verify-full`
- exposes Actuator readiness with database health on the internal management port
- connects by default as the dedicated non-admin role `wortwerk_app`, provisioned by `../data/bootstrap-runtime-db-role.sh`

## Key Outputs

- `container_instance_id`
- `load_balancer_id`
- `selected_availability_domain`
- `deployed_image_url`
- `public_ip` (stable reserved LB public IP)
- `access_url`
- `https_access_url`
