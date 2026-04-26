variable "region" {
  description = "OCI region that hosts the OKE cluster."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID used by Wort-Werk OCI resources."
  type        = string
}

variable "vcn_id" {
  description = "VCN OCID used by the OKE cluster."
  type        = string
}

variable "endpoint_subnet_id" {
  description = "Private subnet OCID used by the OKE API endpoint."
  type        = string
}

variable "worker_subnet_id" {
  description = "Private subnet OCID used by OKE worker nodes."
  type        = string
}

variable "load_balancer_subnet_id" {
  description = "Subnet OCID used for Kubernetes Services of type LoadBalancer."
  type        = string
}

variable "cluster_name" {
  description = "OKE cluster display name."
  type        = string
  default     = "wort-werk-oke"
}

variable "node_pool_name" {
  description = "OKE node pool display name."
  type        = string
  default     = "wort-werk-workers"
}

variable "app_namespace" {
  description = "Stable production namespace used by the blue-green application slots."
  type        = string
  default     = "wortwerk-prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the OKE cluster and node pool."
  type        = string
}

variable "node_image_id" {
  description = "Worker node image OCID used by the OKE node pool."
  type        = string
}

variable "availability_domain" {
  description = "Optional availability domain name for worker placement. Defaults to the first AD in the region when empty."
  type        = string
  default     = ""
}

variable "node_pool_size" {
  description = "Number of worker nodes in the OKE node pool."
  type        = number
  default     = 2
}

variable "node_shape" {
  description = "OCI shape used by the OKE worker nodes."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_shape_ocpus" {
  description = "OCPU allocation for flex worker node shapes."
  type        = number
  default     = 1
}

variable "node_shape_memory_in_gbs" {
  description = "Memory allocation for flex worker node shapes."
  type        = number
  default     = 16
}

variable "pods_cidr" {
  description = "CIDR used by the Kubernetes pod network."
  type        = string
  default     = "10.244.0.0/16"
}

variable "services_cidr" {
  description = "CIDR used by the Kubernetes services network."
  type        = string
  default     = "10.96.0.0/16"
}
