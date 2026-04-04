variable "region" {
  description = "OCI region (example: eu-frankfurt-1)."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID used to resolve availability domains."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID from foundation stack."
  type        = string
}

variable "subnet_id" {
  description = "Subnet OCID from foundation stack."
  type        = string
}

variable "nsg_id" {
  description = "NSG OCID from foundation stack."
  type        = string
}

variable "availability_domain_index" {
  description = "Availability Domain index to use from the tenancy AD list (0-based)."
  type        = number
  default     = 0
}

variable "container_instance_name" {
  description = "Display name of the OCI Container Instance."
  type        = string
  default     = "wort-werk"
}

variable "container_instance_shape" {
  description = "Container Instance shape (example: CI.Standard.A1.Flex or CI.Standard.E4.Flex)."
  type        = string
  default     = "CI.Standard.A1.Flex"
}

variable "image_repository" {
  description = "OCIR repository path without tag, for example fra.ocir.io/<namespace>/wort-werk."
  type        = string
}

variable "image_tag" {
  description = "OCI image tag (recommended: git commit hash)."
  type        = string
}

variable "image_registry_endpoint" {
  description = "Image registry endpoint host, for example fra.ocir.io."
  type        = string
}

variable "image_registry_username" {
  description = "Registry username used by OCI Container Instance to pull private image."
  type        = string
  sensitive   = true
}

variable "image_registry_password" {
  description = "Registry auth token/password used by OCI Container Instance to pull private image."
  type        = string
  sensitive   = true
}

variable "ocpus" {
  description = "Container Instance OCPU allocation."
  type        = number
  default     = 1
}

variable "memory_in_gbs" {
  description = "Container Instance memory allocation in GB."
  type        = number
  default     = 2
}
