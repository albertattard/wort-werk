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
