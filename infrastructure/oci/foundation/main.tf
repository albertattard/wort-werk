provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = var.home_region
}

locals {
  stack_name                        = "wort-werk"
  vault_name                        = local.stack_name
  vault_key_name                    = "${local.stack_name}-secrets"
  public_route_table_name           = "${local.stack_name}-public"
  runtime_route_table_name          = "${local.stack_name}-runtime"
  devops_route_table_name           = "${local.stack_name}-devops"
  database_route_table_name         = "${local.stack_name}-database"
  database_port                     = 5432
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
  devops_runner_policy_description  = "Allows Wort-Werk OCI DevOps resources to manage the infrastructure and release resources required for deployments."
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

resource "oci_core_vcn" "wort_werk" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = local.stack_name
  dns_label      = "wortwerk"
}

resource "oci_core_internet_gateway" "wort_werk" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.stack_name
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
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
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.database_route_table_name
}

# Gives the private DevOps subnet outbound internet access without
# assigning public IPs to build or deploy runners.
# Used for external egress such as source fetches and dependency
# downloads; inbound internet access is still not allowed.
resource "oci_core_nat_gateway" "devops" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.devops_nat_gateway_name
}

# Private gateway to OCI regional services for subnets that should
# stay off the public internet.
# This lets the runtime and DevOps tiers reach OCI-managed
# dependencies, such as Vault, through the Oracle Services Network.
resource "oci_core_service_gateway" "oracle_services" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.service_gateway_name

  services {
    service_id = data.oci_core_services.oracle_services.services[0].id
  }
}

# Route table for the private runtime subnet.
resource "oci_core_route_table" "runtime" {
  compartment_id = var.compartment_ocid
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
  compartment_id = var.compartment_ocid
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
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.runtime_nsg_name
}

# Network Security Group for the load balancer tier.
# This NSG acts as the VNIC-level firewall boundary for the public
# load balancer; ingress and egress rules are defined separately below.
resource "oci_core_network_security_group" "load_balancer" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.load_balancer_nsg_name
}

# Network Security Group for the database tier.
# This NSG acts as the VNIC-level firewall boundary for PostgreSQL
# resources; ingress and egress rules are defined separately below.
resource "oci_core_network_security_group" "database" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.database_nsg_name
}

# Network Security Group for the DevOps tier.
# This NSG acts as the VNIC-level firewall boundary for private build
# and deploy runners; ingress and egress rules are defined separately below.
resource "oci_core_network_security_group" "devops" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.wort_werk.id
  display_name   = local.devops_nsg_name
}

# ----------------------------------------------------------------------------------------------------------------------
# Load Balancer --> Runtime (Application Port)
# ----------------------------------------------------------------------------------------------------------------------
# Allows the runtime tier to receive traffic from the load balancer tier on the application port.
resource "oci_core_network_security_group_security_rule" "runtime_ingress_from_load_balancer_for_application" {
  network_security_group_id = oci_core_network_security_group.runtime.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.load_balancer.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = var.application_port
      max = var.application_port
    }
  }
}

# Allows the load balancer tier to send traffic to the runtime tier on the application port.
resource "oci_core_network_security_group_security_rule" "load_balancer_egress_to_runtime_for_application" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.runtime.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = var.application_port
      max = var.application_port
    }
  }
}
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Load Balancer --> Runtime (Management Port/Health Checks)
# ----------------------------------------------------------------------------------------------------------------------
# Allows the runtime tier to receive traffic from the load balancer tier on the management port.
resource "oci_core_network_security_group_security_rule" "runtime_ingress_from_load_balancer_for_management" {
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

# Allows the load balancer tier to send traffic to the runtime tier on the management port.
resource "oci_core_network_security_group_security_rule" "load_balancer_egress_to_runtime_for_management" {
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
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Runtime --> OCI Services
# ----------------------------------------------------------------------------------------------------------------------
# Allows the runtime tier to send outbound traffic to OCI regional services, such as Vault.
# Only an egress rule is required because the destination is an Oracle-managed service CIDR, not another NSG in this VCN.
resource "oci_core_network_security_group_security_rule" "runtime_egress_to_oci_services" {
  network_security_group_id = oci_core_network_security_group.runtime.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_services.oracle_services.services[0].cidr_block
  destination_type          = "SERVICE_CIDR_BLOCK"
}
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Devops --> OCI Services
# ----------------------------------------------------------------------------------------------------------------------
# Allows the devops tier to send outbound traffic to OCI regional services, such as Vault.
# Only an egress rule is required because the destination is an Oracle-managed service CIDR, not another NSG in this VCN.
resource "oci_core_network_security_group_security_rule" "devops_egress_to_oci_services" {
  network_security_group_id = oci_core_network_security_group.devops.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = data.oci_core_services.oracle_services.services[0].cidr_block
  destination_type          = "SERVICE_CIDR_BLOCK"
}
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Runtime --> Database (Database Port)
# ----------------------------------------------------------------------------------------------------------------------
# Allows the runtime tier to send traffic to the database tier on the database port.
resource "oci_core_network_security_group_security_rule" "runtime_egress_to_database" {
  network_security_group_id = oci_core_network_security_group.runtime.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.database.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = local.database_port
      max = local.database_port
    }
  }
}

# Allows the database tier to receive traffic from the runtime tier on the database port.
resource "oci_core_network_security_group_security_rule" "database_ingress_from_runtime" {
  network_security_group_id = oci_core_network_security_group.database.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.runtime.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = local.database_port
      max = local.database_port
    }
  }
}
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Internet --> Load Balancer (HTTP / HTTPS)
# ----------------------------------------------------------------------------------------------------------------------
# Allows the load balancer to receive traffic from the internet on port 80 (HTTP).
resource "oci_core_network_security_group_security_rule" "load_balancer_ingress_from_internet_for_http" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

# Allows the load balancer to receive traffic from the internet on port 443 (HTTPS).
resource "oci_core_network_security_group_security_rule" "load_balancer_ingress_from_internet_for_https" {
  network_security_group_id = oci_core_network_security_group.load_balancer.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Devops --> Database (Database Port)
# ----------------------------------------------------------------------------------------------------------------------
# Allows the database tier to receive traffic from the devops tier on the database port.
resource "oci_core_network_security_group_security_rule" "database_ingress_from_devops" {
  network_security_group_id = oci_core_network_security_group.database.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.devops.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = local.database_port
      max = local.database_port
    }
  }
}

# Allows the devops tier to send traffic to the database tier on the database port.
resource "oci_core_network_security_group_security_rule" "devops_egress_to_database" {
  network_security_group_id = oci_core_network_security_group.devops.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.database.id
  destination_type          = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = local.database_port
      max = local.database_port
    }
  }
}
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Devops --> Internet (HTTPS only)
# ----------------------------------------------------------------------------------------------------------------------
# Allows the devops tier to send outbound HTTPS traffic to the internet.
# HTTP is intentionally not allowed; external web access from the devops tier is restricted to HTTPS.
resource "oci_core_network_security_group_security_rule" "devops_egress_to_internet_for_https" {
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
# ----------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# Database --> Anywhere
# ----------------------------------------------------------------------------------------------------------------------
# Allows the database tier to send outbound traffic to any destination over any protocol.
# TODO: Verify whether we need to have such an open policy?
# resource "oci_core_network_security_group_security_rule" "database_egress_to_any" {
#   network_security_group_id = oci_core_network_security_group.database.id
#   direction                 = "EGRESS"
#   protocol                  = "all"
#   destination               = "0.0.0.0/0"
#   destination_type          = "CIDR_BLOCK"
# }
# ----------------------------------------------------------------------------------------------------------------------

# Public subnet for the load balancer tier.
# It uses the public route table and permits public IP assignment so the load balancer can accept traffic from the internet.
resource "oci_core_subnet" "load_balancer" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.load_balancer_subnet_cidr
  display_name               = local.stack_name
  dns_label                  = "wortwerk"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false
}

# Private subnet for the runtime tier.
# It uses the runtime route table and forbids public IP assignment so the application runs without direct internet exposure.
resource "oci_core_subnet" "runtime" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.runtime_subnet_cidr
  display_name               = local.runtime_subnet_name
  dns_label                  = "wortrun"
  route_table_id             = oci_core_route_table.runtime.id
  prohibit_public_ip_on_vnic = true
}

# Private subnet for the database tier.
# It uses the database route table and forbids public IP assignment so the database has no direct public network path.
resource "oci_core_subnet" "database" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.database_subnet_cidr
  display_name               = local.database_subnet_name
  dns_label                  = "wortdb"
  route_table_id             = oci_core_route_table.database.id
  prohibit_public_ip_on_vnic = true
}

# Private subnet for the DevOps tier.
# It uses the DevOps route table and forbids public IP assignment so build and deploy runners stay private while using controlled outbound access.
resource "oci_core_subnet" "devops" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.wort_werk.id
  cidr_block                 = var.devops_subnet_cidr
  display_name               = local.devops_subnet_name
  dns_label                  = "wortdev"
  route_table_id             = oci_core_route_table.devops.id
  prohibit_public_ip_on_vnic = true
}

resource "oci_kms_vault" "wort_werk" {
  compartment_id = var.compartment_ocid
  display_name   = local.vault_name
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "wort_werk" {
  compartment_id           = var.compartment_ocid
  display_name             = local.vault_key_name
  management_endpoint      = oci_kms_vault.wort_werk.management_endpoint
  protection_mode          = "SOFTWARE"
  is_auto_rotation_enabled = false

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

# Dynamic group for the runtime container instances.
# This is needed so the runtime tier has an OCI IAM identity that can be granted permissions to access services such as Vault.
resource "oci_identity_dynamic_group" "runtime" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = local.runtime_dynamic_group_name
  description    = local.runtime_dynamic_group_description
  matching_rule  = "ALL {resource.type = 'computecontainerinstance', resource.compartment.id = '${var.compartment_ocid}'}"
}

# Dynamic group for the Wort-Werk OCI DevOps resources.
# This is needed so build, deploy, and related DevOps components have an OCI IAM identity that can be granted the permissions required for releases.
resource "oci_identity_dynamic_group" "devops" {
  provider       = oci.home
  compartment_id = var.tenancy_ocid
  name           = local.devops_dynamic_group_name
  description    = local.devops_dynamic_group_description
  matching_rule  = "ANY {ALL {resource.type = 'devopsbuildpipeline', resource.compartment.id = '${var.compartment_ocid}'}, ALL {resource.type = 'devopsdeploypipeline', resource.compartment.id = '${var.compartment_ocid}'}, ALL {resource.type = 'devopsconnection', resource.compartment.id = '${var.compartment_ocid}'}, ALL {resource.type = 'devopsrepository', resource.compartment.id = '${var.compartment_ocid}'}}"
}

resource "oci_identity_policy" "devops_runner" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = local.devops_runner_policy_name
  description    = local.devops_runner_policy_description
  statements = [
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO MANAGE devops-family               IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO USE    subnets                     IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO USE    vnics                       IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO USE    network-security-groups     IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO MANAGE load-balancers              IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO USE    public-ips                  IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO USE    dhcp-options                IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO USE    ons-topics                  IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO READ   postgres-db-systems         IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO READ   buckets                     IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO MANAGE objects                     IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.bucket.name = '${local.release_handoff_bucket_name}'",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO MANAGE objects                     IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.bucket.name = '${local.terraform_state_bucket_name}'",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO MANAGE compute-container-instances IN COMPARTMENT ID ${var.compartment_ocid}",
    "ALLOW DYNAMIC-GROUP ${local.devops_dynamic_group_name} TO MANAGE compute-containers          IN COMPARTMENT ID ${var.compartment_ocid}"
  ]
}

resource "oci_artifacts_container_repository" "wort_werk" {
  compartment_id = var.compartment_ocid
  display_name   = var.ocir_repository_name
  is_public      = false
}

resource "oci_core_public_ip" "load_balancer" {
  compartment_id = var.compartment_ocid
  display_name   = local.load_balancer_public_ip_name
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}
