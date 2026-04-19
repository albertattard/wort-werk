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
  devops_route_table_name           = "${local.stack_name}-devops"
  database_route_table_name         = "${local.stack_name}-database"
  runtime_nsg_name                  = "${local.stack_name}-runtime"
  load_balancer_nsg_name            = "${local.stack_name}-load-balancer"
  database_nsg_name                 = "${local.stack_name}-database"
  devops_nsg_name                   = "${local.stack_name}-devops"
  runtime_subnet_name               = "${local.stack_name}-runtime"
  database_subnet_name              = "${local.stack_name}-db"
  devops_subnet_name                = "${local.stack_name}-devops"
  runtime_dynamic_group_name        = "${local.stack_name}-container-runtime"
  runtime_dynamic_group_description = "Container instances for Wort-Werk runtime"
  devops_dynamic_group_name         = "${local.stack_name}-devops-runner"
  devops_dynamic_group_description  = "OCI DevOps build and deploy pipelines for Wort-Werk"
  devops_runner_policy_name         = "${local.stack_name}-devops-runner"
  devops_runner_policy_description  = "Least-privilege policy for Wort-Werk OCI DevOps runners"
  release_handoff_bucket_name       = "${local.stack_name}-release-handoff"
  terraform_state_bucket_name       = "${local.stack_name}-terraform-state"
  load_balancer_public_ip_name      = "${local.stack_name}-load-balancer"
  devops_nat_gateway_name           = "${local.stack_name}-devops"
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

  # Sends all outbound internet traffic (0.0.0.0/0) through the
  # Internet Gateway so the subnet can host internet-reachable
  # resources.
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.wort_werk.id
  }
}

# Route table for the database subnet.
# It intentionally defines no custom routes, so the database tier
# relies only on implicit local VCN routing and has no direct
# internet, NAT, or service-gateway path.
# Access is still restricted separately by NSGs; being on the same
# VCN is necessary but does not by itself grant database
# connectivity.
resource "oci_core_route_table" "database" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.database_route_table_name
}

# Gives the private DevOps subnet outbound internet access without
# assigning public IPs to build or deploy runners.
# Used for external egress such as source fetches and dependency
# downloads; inbound internet access is still not allowed.
resource "oci_core_nat_gateway" "devops" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.devops_nat_gateway_name
}

# Private gateway to OCI regional services for subnets that should
# stay off the public internet.
# This lets the runtime and DevOps tiers reach OCI-managed
# dependencies, such as Vault, through the Oracle Services Network.
resource "oci_core_service_gateway" "oracle_services" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.service_gateway_name

  services {
    service_id = data.oci_core_services.oracle_services.services[0].id
  }
}

# Route table for the private runtime subnet.
resource "oci_core_route_table" "runtime" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.runtime_route_table_name

  # Sends OCI regional service traffic through the Service Gateway so
  # the application can reach OCI-managed dependencies, such as Vault,
  # without requiring public internet access.
  route_rules {
    destination       = data.oci_core_services.oracle_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oracle_services.id
  }
}

# Route table for the private DevOps subnet.
resource "oci_core_route_table" "devops" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.devops_route_table_name

  # Sends OCI regional service traffic through the Service Gateway so
  # private runners can reach OCI-managed dependencies without using
  # the public internet.
  route_rules {
    destination       = data.oci_core_services.oracle_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oracle_services.id
  }

  # Sends all other outbound traffic through the DevOps NAT gateway so
  # private runners can reach external systems, such as GitHub, without
  # requiring public IPs.
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.devops.id
  }
}

# Network Security Group for the runtime application tier.
# This NSG acts as the VNIC-level firewall boundary for the container
# instance; ingress and egress rules are defined separately below.
resource "oci_core_network_security_group" "runtime" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.runtime_nsg_name
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

resource "oci_core_network_security_group" "devops" {
  compartment_id = oci_identity_compartment.wort_werk.id
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.devops_nsg_name
}

resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.runtime.id
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
  network_security_group_id = oci_core_network_security_group.runtime.id
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
  network_security_group_id = oci_core_network_security_group.runtime.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_services.oracle_services.services[0].cidr_block
  destination_type          = "SERVICE_CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "egress_postgresql" {
  network_security_group_id = oci_core_network_security_group.runtime.id
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
  destination               = oci_core_network_security_group.runtime.id
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
  destination               = oci_core_network_security_group.runtime.id
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
  source                    = oci_core_network_security_group.runtime.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "db_ingress_postgresql_from_devops" {
  network_security_group_id = oci_core_network_security_group.database.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.devops.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "devops_egress_postgresql" {
  network_security_group_id = oci_core_network_security_group.devops.id
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

resource "oci_core_network_security_group_security_rule" "devops_egress_oci_services" {
  network_security_group_id = oci_core_network_security_group.devops.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_services.oracle_services.services[0].cidr_block
  destination_type          = "SERVICE_CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "devops_egress_https" {
  network_security_group_id = oci_core_network_security_group.devops.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
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
  route_table_id             = oci_core_route_table.database.id
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "devops" {
  compartment_id             = oci_identity_compartment.wort_werk.id
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.devops_subnet_cidr
  display_name               = local.devops_subnet_name
  dns_label                  = "wortdev"
  route_table_id             = oci_core_route_table.devops.id
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

resource "oci_identity_dynamic_group" "devops" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = local.devops_dynamic_group_name
  description    = local.devops_dynamic_group_description
  matching_rule  = "ANY {ALL {resource.type = 'devopsbuildpipeline', resource.compartment.id = '${oci_identity_compartment.wort_werk.id}'}, ALL {resource.type = 'devopsdeploypipeline', resource.compartment.id = '${oci_identity_compartment.wort_werk.id}'}, ALL {resource.type = 'devopsconnection', resource.compartment.id = '${oci_identity_compartment.wort_werk.id}'}, ALL {resource.type = 'devopsrepository', resource.compartment.id = '${oci_identity_compartment.wort_werk.id}'}}"
}

resource "oci_identity_policy" "devops_runner" {
  provider       = oci.home
  compartment_id = oci_identity_compartment.wort_werk.id
  name           = local.devops_runner_policy_name
  description    = local.devops_runner_policy_description
  statements = [
    "Allow dynamic-group ${local.devops_dynamic_group_name} to manage devops-family in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to use subnets in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to use vnics in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to use network-security-groups in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to manage load-balancers in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to use public-ips in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to use dhcp-options in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to use ons-topics in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to read postgres-db-systems in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to read buckets in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to manage objects in compartment id ${oci_identity_compartment.wort_werk.id} where target.bucket.name = '${local.release_handoff_bucket_name}'",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to manage objects in compartment id ${oci_identity_compartment.wort_werk.id} where target.bucket.name = '${local.terraform_state_bucket_name}'",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to manage compute-container-instances in compartment id ${oci_identity_compartment.wort_werk.id}",
    "Allow dynamic-group ${local.devops_dynamic_group_name} to manage compute-containers in compartment id ${oci_identity_compartment.wort_werk.id}"
  ]
}

resource "oci_objectstorage_bucket" "terraform_state" {
  compartment_id = oci_identity_compartment.wort_werk.id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = local.terraform_state_bucket_name
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
  versioning     = "Enabled"
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
