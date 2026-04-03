output "compartment_ocid" {
  description = "Compartment used by Wort-Werk resources."
  value       = local.target_compartment_ocid
}

output "vcn_id" {
  description = "VCN OCID."
  value       = oci_core_vcn.wort_werk.id
}

output "subnet_id" {
  description = "Container subnet OCID."
  value       = oci_core_subnet.container.id
}

output "nsg_id" {
  description = "Network Security Group OCID."
  value       = oci_core_network_security_group.wort_werk.id
}

output "ocir_repository_name" {
  description = "OCIR repository display name."
  value       = oci_artifacts_container_repository.wort_werk.display_name
}

output "container_instance_id" {
  description = "OCI Container Instance OCID."
  value       = oci_container_instances_container_instance.wort_werk.id
}
