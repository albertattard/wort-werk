variable "region" {
  description = "OCI region (example: eu-frankfurt-1)."
  type        = string
}

variable "home_region" {
  description = "OCI home region used for identity resources."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID from foundation stack."
  type        = string
}

variable "database_subnet_id" {
  description = "Database subnet OCID from foundation stack."
  type        = string
}

variable "database_nsg_id" {
  description = "Database NSG OCID from foundation stack."
  type        = string
}

variable "runtime_dynamic_group_name" {
  description = "Dynamic group name created by foundation for runtime container instances."
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL major version for the managed OCI PostgreSQL service."
  type        = string
  default     = "16"
}

variable "postgresql_shape" {
  description = "OCI PostgreSQL shape."
  type        = string
  default     = "PostgreSQL.VM.Standard.E5.Flex.2.32GB"
}

variable "postgresql_instance_count" {
  description = "Number of nodes in the OCI PostgreSQL DB system."
  type        = number
  default     = 1
}

variable "postgresql_admin_username" {
  description = "Administrator username for the OCI PostgreSQL DB system."
  type        = string
  default     = "wortwerk_admin"
}

variable "postgresql_admin_password_secret_ocid" {
  description = "OCI Vault secret OCID containing the PostgreSQL administrator password."
  type        = string
}

variable "postgresql_admin_password_secret_version" {
  description = "Version number of the OCI Vault secret containing the PostgreSQL administrator password."
  type        = number
  default     = 1
}

variable "runtime_db_username" {
  description = "Runtime database username used by the application. Defaults to the admin username until a separate least-privilege app role is provisioned."
  type        = string
  default     = "wortwerk_admin"
}

variable "runtime_db_password_secret_ocid" {
  description = "OCI Vault secret OCID containing the runtime database password used by the application."
  type        = string
  sensitive   = true
}

variable "postgresql_database_name" {
  description = "Database name used in the runtime JDBC URL."
  type        = string
  default     = "postgres"
}

variable "postgresql_backup_start" {
  description = "Daily backup start time in UTC in HH:MM format."
  type        = string
  default     = "02:00"
}

variable "postgresql_backup_retention_days" {
  description = "Retention period for automated OCI PostgreSQL backups."
  type        = number
  default     = 30
}

variable "postgresql_maintenance_window_start" {
  description = "Maintenance window start in UTC using '<day> <HH:MM>' format."
  type        = string
  default     = "sun 03:00"
}
