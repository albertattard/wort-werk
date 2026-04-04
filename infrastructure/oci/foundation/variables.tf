variable "tenancy_ocid" {
  description = "Tenancy OCID."
  type        = string
}

variable "region" {
  description = "OCI region (example: eu-frankfurt-1)."
  type        = string
}

variable "home_region" {
  description = "OCI home region used for tenancy-scoped IAM operations (example: us-ashburn-1)."
  type        = string
}

variable "parent_compartment_ocid" {
  description = "Parent compartment OCID under which the Wort-Werk compartment will be created."
  type        = string
}

variable "compartment_name" {
  description = "Name of the dedicated compartment created for Wort-Werk."
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

variable "lb_listener_port" {
  description = "Public HTTP listener port on the OCI Load Balancer."
  type        = number
  default     = 80
}

variable "load_balancer_min_bandwidth_mbps" {
  description = "Minimum flexible load balancer bandwidth in Mbps."
  type        = number
  default     = 10
}

variable "load_balancer_max_bandwidth_mbps" {
  description = "Maximum flexible load balancer bandwidth in Mbps."
  type        = number
  default     = 10
}

variable "ocir_repository_name" {
  description = "OCIR repository name."
  type        = string
  default     = "wort-werk"
}

variable "ocir_registry" {
  description = "OCIR registry host, for example fra.ocir.io."
  type        = string
  default     = "fra.ocir.io"
}
