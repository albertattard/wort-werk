provider "oci" {
  region = var.region
}

locals {
  cluster_name   = var.cluster_name
  node_pool_name = var.node_pool_name
  freeform_tags = {
    group_id = "wort-werk"
    tier     = "oke"
  }
  worker_availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.this.availability_domains[0].name
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

resource "oci_containerengine_cluster" "wort_werk" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = local.cluster_name
  type               = "ENHANCED_CLUSTER"
  vcn_id             = var.vcn_id

  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = var.endpoint_subnet_id
  }

  options {
    service_lb_subnet_ids = [var.load_balancer_subnet_id]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
  }

  freeform_tags = local.freeform_tags
}

resource "oci_containerengine_node_pool" "wort_werk" {
  cluster_id         = oci_containerengine_cluster.wort_werk.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = local.node_pool_name
  node_shape         = var.node_shape

  node_config_details {
    placement_configs {
      availability_domain = local.worker_availability_domain
      subnet_id           = var.worker_subnet_id
    }

    size = var.node_pool_size
  }

  node_source_details {
    image_id    = var.node_image_id
    source_type = "IMAGE"
  }

  node_shape_config {
    ocpus         = var.node_shape_ocpus
    memory_in_gbs = var.node_shape_memory_in_gbs
  }

  initial_node_labels {
    key   = "wortwerk/role"
    value = "application"
  }

  freeform_tags = local.freeform_tags
}
