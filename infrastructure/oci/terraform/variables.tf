variable "tenancy_ocid" {
  description = "Tenancy OCID (required if create_compartment=true or create_iam_policy=true)."
  type        = string
  default     = ""
}

variable "region" {
  description = "OCI region (example: eu-frankfurt-1)."
  type        = string
}

variable "create_compartment" {
  description = "Create a dedicated compartment for Wort-Werk."
  type        = bool
  default     = false
}

variable "compartment_ocid" {
  description = "Existing compartment OCID used when create_compartment=false."
  type        = string
  default     = ""
}

variable "compartment_name" {
  description = "Compartment name used when create_compartment=true."
  type        = string
  default     = "wort-werk"
}

variable "vcn_cidr" {
  description = "CIDR for the VCN."
  type        = string
  default     = "10.10.0.0/16"
}

variable "container_subnet_cidr" {
  description = "CIDR for the public subnet hosting the Container Instance."
  type        = string
  default     = "10.10.1.0/24"
}

variable "allowed_ingress_cidr" {
  description = "CIDR allowed to access HTTP application port (set to 0.0.0.0/0 for public testing)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Application ingress port exposed by Wort-Werk."
  type        = number
  default     = 8080
}

variable "availability_domain" {
  description = "Availability Domain name where the Container Instance runs."
  type        = string
}

variable "container_instance_name" {
  description = "Display name of the OCI Container Instance."
  type        = string
  default     = "wort-werk"
}

variable "image_url" {
  description = "Full OCIR image URL, for example fra.ocir.io/<namespace>/wort-werk:latest."
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

variable "create_iam_policy" {
  description = "Create IAM policy statements for deploy/push groups in tenancy root compartment."
  type        = bool
  default     = false
}

variable "deployer_group_name" {
  description = "IAM group name that can manage Container Instances in the target compartment."
  type        = string
  default     = "wort-werk-deployers"
}

variable "pusher_group_name" {
  description = "IAM group name that can push images to OCIR."
  type        = string
  default     = "wort-werk-pushers"
}
