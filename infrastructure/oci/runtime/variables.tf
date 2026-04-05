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

variable "load_balancer_nsg_id" {
  description = "Load Balancer NSG OCID from foundation stack."
  type        = string
}

variable "load_balancer_public_ip_id" {
  description = "Reserved public IP OCID for OCI Load Balancer."
  type        = string
}

variable "load_balancer_public_ip" {
  description = "Reserved public IP value for OCI Load Balancer."
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

variable "app_port" {
  description = "Container application port."
  type        = number
  default     = 8080
}

variable "lb_listener_port" {
  description = "Public HTTP listener port on the Load Balancer."
  type        = number
  default     = 80
}

variable "https_listener_port" {
  description = "Public HTTPS listener port on the Load Balancer."
  type        = number
  default     = 443
}

variable "tls_certificate_name" {
  description = "Certificate name stored on the OCI Load Balancer."
  type        = string
  default     = "wortwerk_xyz_terraform"
}

variable "tls_public_certificate_path" {
  description = "Path to PEM public certificate file (fullchain) managed by Terraform."
  type        = string
  default     = "tls/wortwerk.xyz/fullchain.pem"
}

variable "tls_private_key_path" {
  description = "Path to PEM private key file managed by Terraform."
  type        = string
  sensitive   = true
  default     = "tls/wortwerk.xyz/privkey.pem"
}

variable "tls_ca_certificate_path" {
  description = "Optional path to CA certificate chain PEM file."
  type        = string
  default     = ""
}

variable "tls_redirect_host" {
  description = "Host used by HTTP to HTTPS redirect rule."
  type        = string
  default     = "wortwerk.xyz"
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

variable "lb_healthcheck_path" {
  description = "HTTP path used by load balancer backend health checks."
  type        = string
  default     = "/"
}

variable "lb_healthcheck_return_code" {
  description = "Expected HTTP status code for backend health checks."
  type        = number
  default     = 200
}
