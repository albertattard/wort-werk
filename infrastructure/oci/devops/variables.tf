variable "region" {
  description = "OCI region that hosts the Wort-Werk DevOps project."
  type        = string
}

variable "home_region" {
  description = "OCI home region used for identity resources such as DevOps IAM policies."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID used by Wort-Werk OCI resources."
  type        = string
}

variable "devops_subnet_id" {
  description = "Private subnet OCID used by OCI DevOps private build and shell stages."
  type        = string
}

variable "devops_nsg_id" {
  description = "NSG OCID applied to OCI DevOps private build and shell stages."
  type        = string
}

variable "devops_dynamic_group_name" {
  description = "Dynamic group name assigned to OCI DevOps build and deploy resources."
  type        = string
}

variable "repository_url" {
  description = "Git repository URL used as the OCI DevOps build source."
  type        = string
  default     = "https://github.com/albertattard/wort-werk.git"
}

variable "repository_branch" {
  description = "Default branch used when no explicit build-run branch override is provided."
  type        = string
  default     = "main"
}

variable "github_connection_token_secret_ocid" {
  description = "Vault secret OCID that stores the GitHub personal access token used by the OCI DevOps connection."
  type        = string
}

variable "image_repository" {
  description = "OCIR repository path without tag used for runtime releases."
  type        = string
}

variable "image_registry_endpoint" {
  description = "OCIR registry host used for runtime image publication and pulls."
  type        = string
}

variable "image_registry_username" {
  description = "Registry username used by OCI DevOps to publish the runtime image and by runtime to pull it."
  type        = string
}

variable "image_registry_password_secret_ocid" {
  description = "Vault secret OCID that stores the registry auth token used for OCI DevOps image publication and runtime image pulls."
  type        = string
}

variable "runtime_state_bucket_name" {
  description = "Object Storage bucket name that owns the remote runtime Terraform state."
  type        = string
}

variable "region_runtime" {
  description = "OCI region used by runtime resources."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID used by runtime Terraform."
  type        = string
}

variable "runtime_subnet_id" {
  description = "Private runtime subnet OCID from foundation."
  type        = string
}

variable "load_balancer_subnet_id" {
  description = "Public load balancer subnet OCID from foundation."
  type        = string
}

variable "nsg_id" {
  description = "Runtime NSG OCID from foundation."
  type        = string
}

variable "load_balancer_nsg_id" {
  description = "Load balancer NSG OCID from foundation."
  type        = string
}

variable "load_balancer_public_ip_id" {
  description = "Reserved public IP OCID used by the load balancer."
  type        = string
}

variable "load_balancer_public_ip" {
  description = "Reserved public IP value used by the load balancer."
  type        = string
}

variable "app_port" {
  description = "Application port exposed by the runtime container."
  type        = number
}

variable "management_port" {
  description = "Internal management port exposed by the runtime container."
  type        = number
}

variable "lb_listener_port" {
  description = "Public HTTP listener port exposed by the load balancer."
  type        = number
}

variable "https_listener_port" {
  description = "Public HTTPS listener port exposed by the load balancer."
  type        = number
}

variable "load_balancer_min_bandwidth_mbps" {
  description = "Minimum flexible load balancer bandwidth in Mbps."
  type        = number
}

variable "load_balancer_max_bandwidth_mbps" {
  description = "Maximum flexible load balancer bandwidth in Mbps."
  type        = number
}

variable "runtime_db_url" {
  description = "JDBC URL used by the application runtime."
  type        = string
}

variable "runtime_db_username" {
  description = "Database username used by the application runtime."
  type        = string
}

variable "runtime_db_password_secret_ocid" {
  description = "Vault secret OCID that stores the runtime database password."
  type        = string
}

variable "tls_public_certificate_secret_ocid" {
  description = "Vault secret OCID that stores the PEM public certificate bundle used by the OCI Load Balancer."
  type        = string
}

variable "tls_private_key_secret_ocid" {
  description = "Vault secret OCID that stores the PEM private key used by the OCI Load Balancer."
  type        = string
}

variable "tls_ca_certificate_secret_ocid" {
  description = "Optional Vault secret OCID that stores the PEM CA certificate chain used by the OCI Load Balancer."
  type        = string
  default     = ""
}

variable "postgresql_db_system_id" {
  description = "OCI PostgreSQL DB system OCID used to resolve connection details during the build."
  type        = string
}

variable "postgresql_admin_username" {
  description = "PostgreSQL administrator username used for DB bootstrap."
  type        = string
}

variable "postgresql_admin_password_secret_ocid" {
  description = "Vault secret OCID that stores the PostgreSQL administrator password."
  type        = string
}

variable "postgresql_host" {
  description = "Private PostgreSQL endpoint hostname."
  type        = string
}

variable "postgresql_port" {
  description = "Private PostgreSQL endpoint port."
  type        = string
}

variable "postgresql_database_name" {
  description = "Database name used by the application runtime."
  type        = string
}

variable "build_runner_image" {
  description = "Managed OCI DevOps build image used for the build stage."
  type        = string
  default     = "OL8_X86_64_STANDARD_10"
}

variable "shell_stage_shape_name" {
  description = "OCI Container Instance shape used by the private deployment shell stage."
  type        = string
  default     = "CI.Standard.E4.Flex"
}

variable "shell_stage_shape_ocpus" {
  description = "OCPU allocation for the private deployment shell stage."
  type        = number
  default     = 1
}

variable "shell_stage_shape_memory_in_gbs" {
  description = "Memory allocation for the private deployment shell stage."
  type        = number
  default     = 8
}

variable "project_log_retention_duration" {
  description = "Retention duration in days for the OCI DevOps project service log. Must be in 30-day increments."
  type        = number
  default     = 30
}
