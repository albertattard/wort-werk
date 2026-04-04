provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = var.home_region
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

resource "oci_identity_compartment" "wort_werk" {
  provider       = oci.home
  compartment_id = var.parent_compartment_ocid
  name           = var.compartment_name
  description    = "Compartment for Wort-Werk resources"
  enable_delete  = true
}

resource "oci_core_vcn" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "wort-werk"
  dns_label      = "wortwerk"
}

resource "oci_core_internet_gateway" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk-public"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wort_werk.id
  }
}

resource "oci_core_network_security_group" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk-container"
}

resource "oci_core_network_security_group" "load_balancer" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = "wort-werk-load-balancer"
}

resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.wort_werk.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.load_balancer.id
  source_type               = "NETWORK_SECURITY_GROUP"

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

resource "oci_core_network_security_group_security_rule" "lb_ingress_http" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.allowed_ingress_cidr
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = var.lb_listener_port
      max = var.lb_listener_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_ingress_https" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.allowed_ingress_cidr
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = var.https_listener_port
      max = var.https_listener_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_egress_to_container" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.wort_werk.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = var.app_port
      max = var.app_port
    }
  }
}

resource "oci_core_subnet" "container" {
  compartment_id             = oci_identity_compartment.wort_werk.id
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.container_subnet_cidr
  display_name               = "wort-werk"
  dns_label                  = "wortwerk"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false
}

resource "oci_artifacts_container_repository" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  display_name   = var.ocir_repository_name
  is_public      = false
}

resource "oci_core_public_ip" "load_balancer" {
  compartment_id = oci_identity_compartment.wort_werk.id
  display_name   = "wort-werk-load-balancer"
  lifetime       = "RESERVED"

  lifecycle {
    # OCI updates this when the reserved IP is attached to LB-managed private IPs.
    # Ignore drift so Terraform does not try to unassign it.
    ignore_changes = [private_ip_id]
  }
}
