provider "oci" {
  region = var.region
}

locals {
  image_url = "${var.image_repository}:${var.image_tag}"
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_container_instances_container_instance" "wort_werk" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[var.availability_domain_index].name
  display_name        = var.container_instance_name

  shape = "CI.Standard.A1.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  vnics {
    subnet_id             = var.subnet_id
    is_public_ip_assigned = true
    nsg_ids               = [var.nsg_id]
  }

  containers {
    display_name = "wort-werk"
    image_url    = local.image_url

    resource_config {
      memory_limit_in_gbs = var.memory_in_gbs
      vcpus_limit         = var.ocpus
    }
  }
}
