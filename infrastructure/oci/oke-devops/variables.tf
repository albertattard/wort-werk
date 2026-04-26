variable "region" {
  description = "OCI region that hosts the OKE DevOps project."
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

variable "github_connection_token_secret_ocid" {
  description = "Vault secret OCID that stores the GitHub personal access token used by the OCI DevOps connection."
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

variable "image_repository" {
  description = "OCIR repository path without tag used for OKE releases."
  type        = string
}

variable "image_registry_endpoint" {
  description = "OCIR registry host used for image publication and pulls."
  type        = string
}

variable "image_registry_username" {
  description = "Registry username used by OCI DevOps to publish the runtime image and by OKE to pull it."
  type        = string
}

variable "image_registry_password_secret_ocid" {
  description = "Vault secret OCID that stores the registry auth token."
  type        = string
}

variable "oke_cluster_id" {
  description = "OKE cluster OCID targeted by the deploy pipeline."
  type        = string
}

variable "app_namespace" {
  description = "Stable application namespace used by the blue-green rollout."
  type        = string
}

variable "app_base_url" {
  description = "Stable public base URL used for the post-switch smoke test."
  type        = string
}

variable "service_type" {
  description = "Kubernetes Service type used by wortwerk-active."
  type        = string
  default     = "ClusterIP"
}

variable "use_nginx_ingress" {
  description = "Whether the deploy pipeline should also apply the ingress manifest."
  type        = bool
  default     = false
}

variable "app_host" {
  description = "Public host name used by the optional ingress manifest."
  type        = string
  default     = ""
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

variable "runtime_db_ssl_root_cert_base64" {
  description = "Base64-encoded PostgreSQL CA certificate used by the application runtime."
  type        = string
}

variable "post_switch_observation_seconds" {
  description = "Seconds to observe the public endpoint after switching the active Service selector before deleting the previous slot."
  type        = number
  default     = 120
}

variable "post_switch_observation_interval_seconds" {
  description = "Seconds between repeated public endpoint checks during post-switch observation."
  type        = number
  default     = 10
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
