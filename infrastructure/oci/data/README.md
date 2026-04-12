# OCI Data Stack

Data Terraform stack for Wort-Werk managed PostgreSQL.

## Provisions

- OCI Database with PostgreSQL
- runtime secret-read policy scoped to the configured runtime DB password secret
- database connection outputs consumed by runtime

## Depends On

Outputs from `../foundation`:
- `region`
- `home_region`
- `compartment_ocid`
- `database_subnet_id`
- `database_nsg_id`
- `runtime_dynamic_group_name`

## Required Inputs

Create the database password secrets in OCI Vault after foundation apply, then provide:
- `postgresql_admin_password_secret_ocid`
- `runtime_db_password_secret_ocid`

## Set the DB Credentials with OCI CLI

Run this after `foundation` has been applied:

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/data/set-db-secrets.sh
```

The script:
- reads `compartment_ocid`, `vault_id`, and `vault_key_id` from `foundation`
- prompts for the PostgreSQL admin password and runtime DB password
- creates the Vault secrets on first run
- updates the Vault secrets on later runs
- writes `infrastructure/oci/data/terraform.tfvars`
- defaults `runtime_db_username` to `wortwerk_app` unless you override it explicitly

Then apply the `data` stack:

```bash
terraform -chdir=./infrastructure/oci/data init
terraform -chdir=./infrastructure/oci/data plan
terraform -chdir=./infrastructure/oci/data apply
```

If you prefer to avoid interactive prompts, provide the passwords as environment variables for one run:

```bash
OCI_PROFILE="FRANKFURT" \
POSTGRESQL_ADMIN_PASSWORD="<admin-password>" \
RUNTIME_DB_PASSWORD="<runtime-password>" \
./infrastructure/oci/data/set-db-secrets.sh
```

If you want the script to use different secret names:

```bash
OCI_PROFILE="FRANKFURT" \
POSTGRESQL_ADMIN_SECRET_NAME="custom-admin-secret-name" \
RUNTIME_DB_SECRET_NAME="custom-runtime-secret-name" \
./infrastructure/oci/data/set-db-secrets.sh
```

If you prefer to generate passwords locally first:

```bash
openssl rand -base64 24
```

## Usage

```bash
cd infrastructure/oci/data
terraform init
terraform plan
terraform apply
```

The helper script `../deploy.sh data` writes `foundation.auto.tfvars` for shared inputs automatically.

## Bootstrap the Dedicated Runtime DB Role

After the `data` stack has been applied, run the role bootstrap from a machine that can resolve and reach the private PostgreSQL endpoint. This step requires `psql`.

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/deploy.sh db-role
```

Or invoke the helper directly:

```bash
OCI_PROFILE="FRANKFURT" ./infrastructure/oci/data/bootstrap-runtime-db-role.sh
```

The helper:
- reads the PostgreSQL endpoint and CA certificate from `terraform output`
- reads the administrator and runtime DB passwords from OCI Vault
- connects over TLS with `psql`
- creates or rotates the `runtime_db_username` role
- grants only Wort-Werk-owned database/schema privileges on the configured database
- reassigns existing objects in the `public` schema to the runtime role so Flyway can keep evolving the schema without using the administrator account

Re-run this helper after rotating the runtime DB password secret, or after administrator-created schema objects need to be handed back to the runtime role.

## Key Outputs

- `postgresql_db_system_id`
- `postgresql_fqdn`
- `postgresql_port`
- `postgresql_database_name`
- `runtime_db_url`
- `runtime_db_username`
- `runtime_db_password_secret_ocid`
- `runtime_db_ssl_root_cert_base64`
