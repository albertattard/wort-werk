# OKE DevOps Pipeline Contract

This directory contains the OCI DevOps build and deploy configuration for the proposed OKE blue-green runtime.

It now also contains the Terraform stack that provisions the OKE-specific OCI DevOps project, pipelines, and shell stage.

The Terraform stack also provisions a GitHub push trigger for the configured trunk branch.
The trigger excludes changes where the affected paths are only under `docs/**` or `infrastructure/**`, keeping documentation and infrastructure commits outside the automatic application release path.

## Build Pipeline

Use `build_spec.yaml` for the OCI DevOps build pipeline.

Expected responsibilities:

1. install Java 25
2. run `./mvnw clean verify`
3. build the runtime image
4. push the image to OCIR
5. export `APP_IMAGE` for the deploy handoff

Required pipeline variables:

- `IMAGE_REPOSITORY`
- `IMAGE_REGISTRY_ENDPOINT`
- `IMAGE_REGISTRY_USERNAME`
- `IMAGE_REGISTRY_PASSWORD_SECRET_OCID`

## Deploy Pipeline

Use `command_spec.yaml` for the OCI DevOps private shell deployment stage.

Expected responsibilities:

1. install `kubectl`
2. install `envsubst`
3. create kubeconfig for the target OKE cluster
4. resolve the inactive slot from the stable `Service` selector
5. render Kubernetes manifests with the target namespace, slot, image, and service type
6. apply the manifests
7. wait for rollout readiness
8. switch the stable `Service` selector to the target slot
9. observe the public endpoint for the configured post-switch window
10. roll traffic back and stop the failed target slot if observation fails
11. delete the old slot workload only after observation passes

Required deploy variables:

- `OKE_CLUSTER_ID`
- `OCI_REGION`
- `APP_BASE_URL`
- `APP_NAMESPACE`
- `APP_IMAGE`
- `IMAGE_REGISTRY_ENDPOINT`
- `IMAGE_REGISTRY_USERNAME`
- `IMAGE_REGISTRY_PASSWORD_SECRET_OCID`
- `RUNTIME_DB_URL`
- `RUNTIME_DB_USERNAME`
- `RUNTIME_DB_PASSWORD_SECRET_OCID`
- `RUNTIME_DB_SSL_ROOT_CERT_BASE64`

Optional deploy variables:

- `USE_NGINX_INGRESS`
- `APP_HOST`
- `SERVICE_TYPE`
- `POST_SWITCH_OBSERVATION_SECONDS`, default `120`
- `POST_SWITCH_OBSERVATION_INTERVAL_SECONDS`, default `10`

## Important Constraint

The deploy flow assumes public ingress already targets the stable `wortwerk-active` `Service`.
The blue-green cutover itself happens by changing the `Service` selector, not by modifying the public edge on each release.

## Terraform Stack

Apply:

```bash
cd infrastructure/oci/oke-devops
terraform init
terraform plan
terraform apply
```

Required Terraform inputs:

- `region`
- `home_region`
- `compartment_ocid`
- `devops_subnet_id`
- `devops_nsg_id`
- `devops_dynamic_group_name`
- `github_connection_token_secret_ocid`
- `image_repository`
- `image_registry_endpoint`
- `image_registry_username`
- `image_registry_password_secret_ocid`
- `oke_cluster_id`
- `app_namespace`
- `app_base_url`
- `runtime_db_url`
- `runtime_db_username`
- `runtime_db_password_secret_ocid`
- `runtime_db_ssl_root_cert_base64`
- `post_switch_observation_seconds`
- `post_switch_observation_interval_seconds`

Trigger a release after apply:

```bash
./infrastructure/oci/oke-devops/run-release.sh
```

The manual trigger remains useful for the first release or for operator-controlled retries.
Normal application/runtime changes on the configured repository branch should use the OCI DevOps GitHub push trigger after the stack is applied.
