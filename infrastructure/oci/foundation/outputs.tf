output "compartment_ocid" {
  description = "Compartment OCID used by Wort-Werk resources."
  value       = oci_identity_compartment.wort_werk.id
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

output "ocir_namespace" {
  description = "Object Storage/OCIR namespace."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "ocir_repository_name" {
  description = "OCIR repository display name."
  value       = oci_artifacts_container_repository.wort_werk.display_name
}
