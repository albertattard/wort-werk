output "postgresql_db_system_id" {
  description = "OCI PostgreSQL DB system OCID."
  value       = oci_psql_db_system.wort_werk.id
}

output "postgresql_fqdn" {
  description = "Private FQDN of the OCI PostgreSQL primary endpoint."
  value       = data.oci_psql_db_system_connection_detail.wort_werk.primary_db_endpoint[0].fqdn
}

output "postgresql_port" {
  description = "Port of the OCI PostgreSQL primary endpoint."
  value       = data.oci_psql_db_system_connection_detail.wort_werk.primary_db_endpoint[0].port
}

output "postgresql_database_name" {
  description = "Database name used by the runtime JDBC URL."
  value       = var.postgresql_database_name
}

output "postgresql_admin_username" {
  description = "Administrator role used for privileged PostgreSQL bootstrap operations."
  value       = var.postgresql_admin_username
}

output "postgresql_admin_password_secret_ocid" {
  description = "OCI Vault secret OCID that stores the PostgreSQL administrator password."
  value       = var.postgresql_admin_password_secret_ocid
  sensitive   = true
}

output "runtime_db_username" {
  description = "Runtime database username configured for the application."
  value       = local.runtime_db_username
}

output "runtime_db_password_secret_ocid" {
  description = "OCI Vault secret OCID used by the runtime to load the database password."
  value       = var.runtime_db_password_secret_ocid
  sensitive   = true
}

output "runtime_db_ssl_root_cert_base64" {
  description = "Base64-encoded PostgreSQL service CA certificate for runtime TLS verification."
  value       = base64encode(data.oci_psql_db_system_connection_detail.wort_werk.ca_certificate)
  sensitive   = true
}

output "runtime_db_url" {
  description = "JDBC URL used by the application runtime."
  value       = "jdbc:postgresql://${data.oci_psql_db_system_connection_detail.wort_werk.primary_db_endpoint[0].fqdn}:${data.oci_psql_db_system_connection_detail.wort_werk.primary_db_endpoint[0].port}/${var.postgresql_database_name}?sslmode=verify-full"
}
