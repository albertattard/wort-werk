output "container_instance_id" {
  description = "OCI Container Instance OCID."
  value       = oci_container_instances_container_instance.wort_werk.id
}

output "selected_availability_domain" {
  description = "Availability Domain selected for the Container Instance."
  value       = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain_index].name
}

output "deployed_image_url" {
  description = "Resolved container image URL used by the Container Instance."
  value       = local.image_url
}

output "public_ip" {
  description = "Stable reserved public IP assigned to the Load Balancer."
  value       = var.load_balancer_public_ip
}

output "access_url" {
  description = "Primary URL for accessing Wort-Werk through the Load Balancer."
  value       = "https://${var.tls_redirect_host}:${var.https_listener_port}"
}

output "https_access_url" {
  description = "HTTPS endpoint."
  value       = "https://${var.tls_redirect_host}:${var.https_listener_port}"
}

output "load_balancer_id" {
  description = "OCI Load Balancer OCID."
  value       = oci_load_balancer_load_balancer.wort_werk.id
}
