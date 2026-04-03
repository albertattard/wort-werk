provider "oci" {
  region = var.region
}

locals {
  target_compartment_ocid = var.create_compartment ? oci_identity_compartment.wort_werk[0].id : var.compartment_ocid
}

resource "oci_identity_compartment" "wort_werk" {
  count          = var.create_compartment ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = var.compartment_name
  description    = "Compartment for Wort-Werk resources"
  enable_delete  = true
}

resource "oci_core_vcn" "wort_werk" {
  compartment_id = local.target_compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "wort-werk-vcn"
  dns_label      = "wortwerkvcn"
}

resource "oci_core_internet_gateway" "wort_werk" {
  compartment_id = local.target_compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk-igw"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = local.target_compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wort_werk.id
  }
}

resource "oci_core_network_security_group" "wort_werk" {
  compartment_id = local.target_compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk-nsg"
}

resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.wort_werk.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.allowed_ingress_cidr
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = var.app_port
      max = var.app_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.wort_werk.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_subnet" "container" {
  compartment_id             = local.target_compartment_ocid
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.container_subnet_cidr
  display_name               = "wort-werk-container-subnet"
  dns_label                  = "wortwerksubnet"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false
}

resource "oci_artifacts_container_repository" "wort_werk" {
  compartment_id = local.target_compartment_ocid
  display_name   = "wort-werk"
  is_public      = false
}

resource "oci_container_instances_container_instance" "wort_werk" {
  compartment_id      = local.target_compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.container_instance_name

  shape = "CI.Standard.E4.Flex"

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  vnics {
    subnet_id             = oci_core_subnet.container.id
    is_public_ip_assigned = true
    nsg_ids               = [oci_core_network_security_group.wort_werk.id]
  }

  containers {
    display_name = "wort-werk"
    image_url    = var.image_url

    resource_config {
      memory_limit_in_gbs = var.memory_in_gbs
      vcpus_limit         = var.ocpus
    }
  }
}

resource "oci_identity_policy" "wort_werk" {
  count          = var.create_iam_policy ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "wort-werk-deployment-policy"
  description    = "Allows pushing container images and deploying Wort-Werk Container Instance"

  statements = [
    "Allow group ${var.pusher_group_name} to manage repos in compartment id ${local.target_compartment_ocid}",
    "Allow group ${var.pusher_group_name} to read repos in tenancy",
    "Allow group ${var.deployer_group_name} to manage instances in compartment id ${local.target_compartment_ocid}",
    "Allow group ${var.deployer_group_name} to use virtual-network-family in compartment id ${local.target_compartment_ocid}",
    "Allow group ${var.deployer_group_name} to read repos in tenancy"
  ]
}
