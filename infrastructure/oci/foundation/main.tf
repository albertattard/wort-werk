provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = var.home_region
}

locals {
  stack_name                        = "wort-werk"
  compartment_description           = "Compartment for Wort-Werk resources"
  vault_name                        = local.stack_name
  vault_key_name                    = "${local.stack_name}-secrets"
  public_route_table_name           = "${local.stack_name}-public"
  runtime_route_table_name          = "${local.stack_name}-runtime"
  private_route_table_name          = "${local.stack_name}-private"
  container_nsg_name                = "${local.stack_name}-container"
  load_balancer_nsg_name            = "${local.stack_name}-load-balancer"
  database_nsg_name                 = "${local.stack_name}-database"
  runtime_subnet_name               = "${local.stack_name}-runtime"
  database_subnet_name              = "${local.stack_name}-db"
  runtime_dynamic_group_name        = "${local.stack_name}-container-runtime"
  runtime_dynamic_group_description = "Container instances for Wort-Werk runtime"
  load_balancer_public_ip_name      = "${local.stack_name}-load-balancer"
  service_gateway_name              = "${local.stack_name}-services"
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_services" "oracle_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_identity_compartment" "wort_werk" {
  provider       = oci.home
  compartment_id = var.parent_compartment_ocid
  name           = var.compartment_name
  description    = local.compartment_description
  enable_delete  = true
}

resource "oci_core_vcn" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = local.stack_name
  dns_label      = "wortwerk"
}

resource "oci_core_internet_gateway" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.stack_name
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.public_route_table_name

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wort_werk.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.private_route_table_name
}

resource "oci_core_service_gateway" "oracle_services" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.service_gateway_name

  services {
    service_id = data.oci_core_services.oracle_services.services[0].id
  }
}

resource "oci_core_route_table" "runtime" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.runtime_route_table_name

  route_rules {
    destination       = data.oci_core_services.oracle_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oracle_services.id
  }
}

resource "oci_core_network_security_group" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.container_nsg_name
}

resource "oci_core_network_security_group" "load_balancer" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.load_balancer_nsg_name
}

resource "oci_core_network_security_group" "database" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.database_nsg_name
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

resource "oci_core_network_security_group_security_rule" "ingress_management" {
  network_security_group_id = oci_core_network_security_group.wort_werk.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.load_balancer.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = var.management_port
      max = var.management_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_oci_services" {
  network_security_group_id = oci_core_network_security_group.wort_werk.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_services.oracle_services.services[0].cidr_block
  destination_type          = "SERVICE_CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "egress_postgresql" {
  network_security_group_id = oci_core_network_security_group.wort_werk.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.database.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
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

resource "oci_core_network_security_group_security_rule" "lb_egress_to_container_management" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.wort_werk.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = var.management_port
      max = var.management_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "db_ingress_postgresql" {
  network_security_group_id = oci_core_network_security_group.database.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.wort_werk.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "db_egress_all" {
  network_security_group_id = oci_core_network_security_group.database.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_subnet" "container" {
  compartment_id             = oci_identity_compartment.wort_werk.id
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.container_subnet_cidr
  display_name               = local.stack_name
  dns_label                  = "wortwerk"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false
}

resource "oci_core_subnet" "runtime" {
  compartment_id             = oci_identity_compartment.wort_werk.id
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.runtime_subnet_cidr
  display_name               = local.runtime_subnet_name
  dns_label                  = "wortrun"
  route_table_id             = oci_core_route_table.runtime.id
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "database" {
  compartment_id             = oci_identity_compartment.wort_werk.id
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.database_subnet_cidr
  display_name               = local.database_subnet_name
  dns_label                  = "wortdb"
  route_table_id             = oci_core_route_table.private.id
  prohibit_public_ip_on_vnic = true
}

resource "oci_kms_vault" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  display_name   = local.vault_name
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "wort_werk" {
  compartment_id           = oci_identity_compartment.wort_werk.id
  display_name             = local.vault_key_name
  management_endpoint      = oci_kms_vault.wort_werk.management_endpoint
  protection_mode          = "SOFTWARE"
  is_auto_rotation_enabled = false

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_identity_dynamic_group" "runtime" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = local.runtime_dynamic_group_name
  description    = local.runtime_dynamic_group_description
  matching_rule  = "ALL {resource.type = 'computecontainerinstance', resource.compartment.id = '${oci_identity_compartment.wort_werk.id}'}"
}

resource "oci_artifacts_container_repository" "wort_werk" {
  compartment_id = oci_identity_compartment.wort_werk.id
  display_name   = var.ocir_repository_name
  is_public      = false
}

resource "oci_core_public_ip" "load_balancer" {
  compartment_id = oci_identity_compartment.wort_werk.id
  display_name   = local.load_balancer_public_ip_name
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}
