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

variable "image_repository" {
  description = "OCIR repository path without tag, for example fra.ocir.io/<namespace>/wort-werk."
  type        = string
}

variable "image_tag" {
  description = "OCI image tag (recommended: git commit hash)."
  type        = string
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
