# Runtime TLS Staging

This directory is no longer a Terraform input path.
Production rollouts read load balancer TLS material from OCI Vault.

If you temporarily stage certificate files locally while preparing a Vault update, treat this directory as scratch space only and do not rely on it for deployment.
Use `../set-tls-secrets.sh` to publish the PEM material into OCI Vault and update `runtime/terraform.tfvars` with the resulting secret OCIDs.
