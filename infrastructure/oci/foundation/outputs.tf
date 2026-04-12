output "compartment_ocid" {
  description = "Compartment OCID used by Wort-Werk resources."
  value       = oci_identity_compartment.wort_werk.id
}

output "region" {
  description = "Runtime OCI region."
  value       = var.region
}

output "home_region" {
  description = "OCI home region used for identity resources."
  value       = var.home_region
}

output "tenancy_ocid" {
  description = "Tenancy OCID."
  value       = var.tenancy_ocid
}

output "vcn_id" {
  description = "VCN OCID."
  value       = oci_core_vcn.wort_werk.id
}

output "subnet_id" {
  description = "Container subnet OCID."
  value       = oci_core_subnet.container.id
}

output "database_subnet_id" {
  description = "Private database subnet OCID."
  value       = oci_core_subnet.database.id
}

output "nsg_id" {
  description = "Network Security Group OCID."
  value       = oci_core_network_security_group.wort_werk.id
}

output "database_nsg_id" {
  description = "Database Network Security Group OCID."
  value       = oci_core_network_security_group.database.id
}

output "load_balancer_nsg_id" {
  description = "Load Balancer Network Security Group OCID."
  value       = oci_core_network_security_group.load_balancer.id
}

output "load_balancer_public_ip_id" {
  description = "Reserved public IP OCID used by the Load Balancer."
  value       = oci_core_public_ip.load_balancer.id
}

output "load_balancer_public_ip" {
  description = "Reserved public IP address used by the Load Balancer."
  value       = oci_core_public_ip.load_balancer.ip_address
}

output "app_port" {
  description = "Application port exposed by the container backend."
  value       = var.app_port
}

output "management_port" {
  description = "Internal Spring Actuator management port used by load balancer health checks."
  value       = var.management_port
}

output "lb_listener_port" {
  description = "Public listener port exposed by the OCI Load Balancer."
  value       = var.lb_listener_port
}

output "https_listener_port" {
  description = "Public HTTPS listener port exposed by the OCI Load Balancer."
  value       = var.https_listener_port
}

output "load_balancer_min_bandwidth_mbps" {
  description = "Minimum flexible load balancer bandwidth in Mbps."
  value       = var.load_balancer_min_bandwidth_mbps
}

output "load_balancer_max_bandwidth_mbps" {
  description = "Maximum flexible load balancer bandwidth in Mbps."
  value       = var.load_balancer_max_bandwidth_mbps
}

output "ocir_namespace" {
  description = "Object Storage/OCIR namespace."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "vault_id" {
  description = "OCI Vault OCID used for Wort-Werk secrets."
  value       = oci_kms_vault.wort_werk.id
}

output "vault_management_endpoint" {
  description = "OCI Vault management endpoint."
  value       = oci_kms_vault.wort_werk.management_endpoint
}

output "vault_key_id" {
  description = "OCI Vault key OCID used to encrypt secrets."
  value       = oci_kms_key.wort_werk.id
}

output "runtime_dynamic_group_name" {
  description = "Dynamic group name for Wort-Werk runtime container instances."
  value       = oci_identity_dynamic_group.runtime.name
}

output "ocir_repository_name" {
  description = "OCIR repository display name."
  value       = oci_artifacts_container_repository.wort_werk.display_name
}

output "ocir_repository_id" {
  description = "OCIR repository OCID."
  value       = oci_artifacts_container_repository.wort_werk.id
}

output "ocir_registry" {
  description = "OCIR registry host (for example fra.ocir.io)."
  value       = var.ocir_registry
}

output "image_repository" {
  description = "Runtime image repository URL without tag."
  value       = "${var.ocir_registry}/${data.oci_objectstorage_namespace.this.namespace}/${oci_artifacts_container_repository.wort_werk.display_name}"
}
