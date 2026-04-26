# OKE Blue-Green Runtime Design

This directory contains the repository-tracked design artifacts for moving Wort-Werk from a single OCI Container Instance runtime to Oracle Kubernetes Engine (OKE).

It now also contains the Terraform stack that provisions the base OKE cluster and node pool for this rollout model.

## Recommendation

Use OKE with one stable production namespace and two fixed slots:

- namespace: `wortwerk-prod`
- Deployments: `wortwerk-blue` and `wortwerk-green`
- stable Service: `wortwerk-active`

Deploy the new version into the inactive slot, wait for Kubernetes readiness, then switch the stable `Service` selector to the new slot.

Recommended edge:

- a stable public endpoint that targets `wortwerk-active`
- either ingress-nginx or an OCI load balancer-backed `Service`

Optional edge:

- ingress-nginx with an `Ingress` that routes to `wortwerk-active`
- direct OCI load balancer exposure by setting the stable `Service` type to `LoadBalancer`

For production `https://wortwerk.xyz`, ingress-nginx must be configured with a Kubernetes TLS secret named `wortwerk-tls`.
The OKE DevOps rollout creates that secret from OCI Vault certificate secrets before applying the ingress manifest.

The recommendation is deliberate.
Your requirement is to keep the old version live until the new version is ready, then switch and delete the old one.
That is better served by a stable in-cluster `Service` than by introducing cross-namespace coordination and edge-level cutover.

## Target Topology

```text
Internet
  -> ingress-nginx or OCI Load Balancer
      -> Service wortwerk-active

OKE cluster
  -> namespace wortwerk-prod
      -> Deployment wortwerk-blue
      -> Deployment wortwerk-green
      -> Service wortwerk-active
```

## Rollout Sequence

1. OCI DevOps build pipeline checks out an explicit commit.
2. Build pipeline runs `./mvnw clean verify`.
3. Build pipeline builds `ocir/.../wort-werk:<commit-sha>` and pushes it to OCIR.
4. Deploy pipeline resolves the active slot from the `wortwerk-active` `Service` selector.
5. Deploy pipeline applies the target slot `Deployment` in `wortwerk-prod`.
6. Deploy pipeline waits for:
   - `kubectl rollout status`
   - Pod readiness
7. Deploy pipeline updates the `wortwerk-active` `Service` selector to the target slot.
8. Deploy pipeline repeatedly checks the stable public application URL during a configurable post-switch observation window.
9. If observation fails, deploy pipeline switches `wortwerk-active` back to the previous slot and stops the failed target slot.
10. If observation passes, deploy pipeline deletes the old slot `Deployment`.

## Rollback Position

Automatic decommissioning of the old slot is part of the requirement, but it is not free.
It lowers steady-state cost, yet it removes the easiest rollback path.

The deploy path preserves fast rollback during the post-switch observation window.
After that window passes, the previous slot is deleted automatically and rollback becomes a new deployment rather than a selector flip.

If fast rollback becomes more important than cost, keep the old slot alive until the next successful release instead of deleting it immediately.
That would be a conscious change to the current requirement, not a no-risk default.

## Manifest Layout

- `manifests/namespace.yaml.tpl`
- `manifests/deployment.yaml.tpl`
- `manifests/service.yaml.tpl`
- `manifests/ingress.yaml.tpl`

Templates use environment-variable substitution through `envsubst` inside the OCI DevOps deploy stage.

Important manifest assumptions:

- `Deployment` uses readiness and liveness probes on Spring Actuator endpoints.
- `Service` is the blue-green switch primitive and points to the active slot via label selector.
- `Ingress` is included as an optional ingress-nginx exposure pattern and always routes to `wortwerk-active`.
- The deploy stage creates two Kubernetes secrets before rollout:
  - `wortwerk-registry` for OCIR pulls
  - `wortwerk-runtime` for runtime DB settings and probe-related environment variables

## Terraform Stack

The OKE Terraform stack provisions:

- one private OKE cluster
- one worker node pool
- cluster wiring for Kubernetes `LoadBalancer` services on the configured public subnet

Required inputs:

- `region`
- `compartment_ocid`
- `vcn_id`
- `endpoint_subnet_id`
- `worker_subnet_id`
- `load_balancer_subnet_id`
- `kubernetes_version`
- `node_image_id`

Recommended current mapping from `foundation` outputs:

- `vcn_id` -> `foundation:vcn_id`
- `endpoint_subnet_id` -> `foundation:oke_endpoint_subnet_id`
- `worker_subnet_id` -> `foundation:oke_worker_subnet_id`
- `load_balancer_subnet_id` -> `foundation:load_balancer_subnet_id`

Apply:

```bash
cd infrastructure/oci/oke-runtime
terraform init
terraform plan
terraform apply
```

The stack intentionally does not replace the existing `foundation` stack yet.
It consumes the existing VCN and OKE-specific subnet outputs so the migration can be introduced without redesigning all OCI networking in the same change.

## Optional Ingress Bootstrap

To bootstrap ingress-nginx after the cluster exists:

```bash
export OKE_CLUSTER_ID='<oke-cluster-ocid>'
export OCI_REGION='eu-frankfurt-1'
export OCI_LB_SUBNET_ID='<public-load-balancer-subnet-ocid>'
./infrastructure/oci/oke-runtime/bootstrap-ingress-nginx.sh
```

Requirements:

- `oci`
- `kubectl`
- `helm`

If you are outside the OCI VCN, the private OKE endpoint is not reachable directly from your laptop.
In that case, provision the optional OKE admin bastion in `foundation` and use the bastion helper instead:

```bash
export OKE_CLUSTER_ID='<oke-cluster-ocid>'
export OCI_REGION='eu-frankfurt-1'
export OCI_BASTION_ID='<foundation-oke-admin-bastion-ocid>'
export OCI_LB_SUBNET_ID='<public-load-balancer-subnet-ocid>'
export BASTION_SSH_PUBLIC_KEY_FILE="$HOME/.ssh/id_ed25519.pub"
export BASTION_SSH_PRIVATE_KEY_FILE="$HOME/.ssh/id_ed25519"
./infrastructure/oci/oke-runtime/bootstrap-ingress-nginx-via-bastion.sh
```

The bastion helper creates a time-limited OCI Bastion port-forwarding session to the private Kubernetes API endpoint, rewrites the kubeconfig server to `127.0.0.1`, preserves TLS validation with the original VCN hostname, and then delegates to `bootstrap-ingress-nginx.sh`.

## Required Pipeline Inputs

Build pipeline:

- `IMAGE_REPOSITORY`
- `IMAGE_REGISTRY_ENDPOINT`
- `IMAGE_REGISTRY_USERNAME`
- `IMAGE_REGISTRY_PASSWORD_SECRET_OCID`

Deploy pipeline:

- `OKE_CLUSTER_ID`
- `OCI_REGION`
- `APP_BASE_URL`
- `APP_NAMESPACE`
- `APP_IMAGE`
- `APP_HOST` when optional ingress-nginx exposure is enabled
- `SERVICE_TYPE` when exposing the stable `Service` directly through an OCI load balancer
- `TLS_PUBLIC_CERTIFICATE_SECRET_OCID` when optional ingress-nginx exposure is enabled
- `TLS_PRIVATE_KEY_SECRET_OCID` when optional ingress-nginx exposure is enabled
- `TLS_CA_CERTIFICATE_SECRET_OCID` when the certificate chain is stored separately
- `IMAGE_REGISTRY_ENDPOINT`
- `IMAGE_REGISTRY_USERNAME`
- `IMAGE_REGISTRY_PASSWORD_SECRET_OCID`
- `RUNTIME_DB_URL`
- `RUNTIME_DB_USERNAME`
- `RUNTIME_DB_PASSWORD_SECRET_OCID`
- `RUNTIME_DB_SSL_ROOT_CERT_BASE64`

The OCI DevOps stack that uses these rollout assets now lives at:

- `infrastructure/oci/oke-devops/`

## Switch Contract

The OKE design assumes `wortwerk-active` selects one slot label at a time:

- `app.kubernetes.io/slot=blue`
- `app.kubernetes.io/slot=green`

Traffic switches when OCI DevOps reapplies the stable `Service` with the new slot selector after the target slot rollout succeeds.
