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
  description = "Public IP assigned to the Container Instance VNIC."
  value       = try(data.oci_core_vnic.wort_werk.public_ip_address, null)
}

output "access_url" {
  description = "Direct HTTP URL for accessing Wort-Werk."
  value       = try("http://${data.oci_core_vnic.wort_werk.public_ip_address}:8080", null)
}
