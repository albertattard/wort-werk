provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = var.home_region
}

locals {
  stack_name                    = "wort-werk"
  postgresql_display_name       = "${local.stack_name}-postgresql"
  postgresql_description        = "Managed PostgreSQL for Wort-Werk"
  runtime_db_username           = trimspace(var.runtime_db_username)
  runtime_secret_read_policy    = "${local.stack_name}-runtime-secret-read"
  runtime_secret_read_statement = "Allow Wort-Werk container instances to read the runtime DB password secret bundle"
  freeform_tags = {
    group_id = local.stack_name
    tier     = "data"
  }
}

resource "oci_identity_policy" "runtime_secret_read" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = local.runtime_secret_read_policy
  description    = local.runtime_secret_read_statement
  statements = [
    "ALLOW DYNAMIC-GROUP ${var.runtime_dynamic_group_name} TO READ secret-family  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.runtime_db_password_secret_ocid}'",
    "ALLOW DYNAMIC-GROUP ${var.runtime_dynamic_group_name} TO READ secret-bundles IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.runtime_db_password_secret_ocid}'"
  ]
  freeform_tags = local.freeform_tags
}

resource "oci_psql_db_system" "wort_werk" {
  compartment_id              = var.compartment_ocid
  display_name                = local.postgresql_display_name
  description                 = local.postgresql_description
  db_version                  = var.postgresql_version
  shape                       = var.postgresql_shape
  instance_count              = var.postgresql_instance_count
  instance_ocpu_count         = var.postgresql_instance_ocpu_count
  instance_memory_size_in_gbs = var.postgresql_instance_memory_size_in_gbs

  credentials {
    username = var.postgresql_admin_username

    password_details {
      password_type  = "VAULT_SECRET"
      secret_id      = var.postgresql_admin_password_secret_ocid
      secret_version = var.postgresql_admin_password_secret_version
    }
  }

  management_policy {
    backup_policy {
      kind           = "DAILY"
      backup_start   = var.postgresql_backup_start
      retention_days = var.postgresql_backup_retention_days
    }

    maintenance_window_start = var.postgresql_maintenance_window_start
  }

  network_details {
    subnet_id                  = var.database_subnet_id
    nsg_ids                    = [var.database_nsg_id]
    is_reader_endpoint_enabled = false
  }

  storage_details {
    is_regionally_durable = true
    system_type           = "OCI_OPTIMIZED_STORAGE"
  }

  lifecycle {
    precondition {
      condition     = var.postgresql_admin_password_secret_ocid != "" && var.runtime_db_password_secret_ocid != ""
      error_message = "postgresql_admin_password_secret_ocid and runtime_db_password_secret_ocid must both be set."
    }

    precondition {
      condition     = local.runtime_db_username != "" && local.runtime_db_username != var.postgresql_admin_username
      error_message = "runtime_db_username must be a dedicated non-admin application role and must not equal postgresql_admin_username."
    }
  }

  freeform_tags = local.freeform_tags
}

data "oci_psql_db_system_connection_detail" "wort_werk" {
  db_system_id = oci_psql_db_system.wort_werk.id
}
