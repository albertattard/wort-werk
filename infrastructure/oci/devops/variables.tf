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
