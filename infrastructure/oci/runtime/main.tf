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

  shape = var.container_instance_shape

  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory_in_gbs
  }

  vnics {
    subnet_id             = var.subnet_id
    is_public_ip_assigned = true
    nsg_ids               = [var.nsg_id]
  }

  image_pull_secrets {
    secret_type       = "BASIC"
    registry_endpoint = var.image_registry_endpoint
    username          = base64encode(var.image_registry_username)
    password          = base64encode(var.image_registry_password)
  }

  containers {
    display_name = "wort-werk"
    image_url    = local.image_url

    resource_config {
      memory_limit_in_gbs = var.memory_in_gbs
      vcpus_limit         = var.ocpus
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_load_balancer" "wort_werk" {
  compartment_id             = var.compartment_ocid
  display_name               = "wort-werk"
  shape                      = "flexible"
  subnet_ids                 = [var.subnet_id]
  network_security_group_ids = [var.load_balancer_nsg_id]

  shape_details {
    minimum_bandwidth_in_mbps = var.load_balancer_min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.load_balancer_max_bandwidth_mbps
  }

  reserved_ips {
    id = var.load_balancer_public_ip_id
  }
}

resource "oci_load_balancer_backend_set" "wort_werk" {
  name             = "wort-werk-backend-set"
  load_balancer_id = oci_load_balancer_load_balancer.wort_werk.id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol    = "HTTP"
    port        = var.app_port
    url_path    = var.lb_healthcheck_path
    return_code = var.lb_healthcheck_return_code
  }
}

resource "oci_load_balancer_backend" "wort_werk" {
  load_balancer_id = oci_load_balancer_load_balancer.wort_werk.id
  backendset_name  = oci_load_balancer_backend_set.wort_werk.name
  ip_address       = oci_container_instances_container_instance.wort_werk.vnics[0].private_ip
  port             = var.app_port
  weight           = 1

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_listener" "http" {
  load_balancer_id         = oci_load_balancer_load_balancer.wort_werk.id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.wort_werk.name
  port                     = var.lb_listener_port
  protocol                 = "HTTP"
  rule_set_names           = [oci_load_balancer_rule_set.http_to_https.name]
}

resource "oci_load_balancer_certificate" "wort_werk_tls" {
  certificate_name   = var.tls_certificate_name
  load_balancer_id   = oci_load_balancer_load_balancer.wort_werk.id
  public_certificate = file(var.tls_public_certificate_path)
  private_key        = file(var.tls_private_key_path)
  ca_certificate     = var.tls_ca_certificate_path != "" ? file(var.tls_ca_certificate_path) : null
}

resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.wort_werk.id
  name                     = "https"
  default_backend_set_name = oci_load_balancer_backend_set.wort_werk.name
  port                     = var.https_listener_port
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.wort_werk_tls.certificate_name
    protocols               = ["TLSv1.2"]
    verify_peer_certificate = false
    verify_depth            = 0
  }
}

resource "oci_load_balancer_rule_set" "http_to_https" {
  load_balancer_id = oci_load_balancer_load_balancer.wort_werk.id
  name             = "http_to_https"

  items {
    action = "REDIRECT"

    conditions {
      attribute_name  = "PATH"
      attribute_value = "/"
      operator        = "PREFIX_MATCH"
    }

    response_code = 301

    redirect_uri {
      host     = var.tls_redirect_host
      path     = "{path}"
      port     = var.https_listener_port
      protocol = "HTTPS"
      query    = "{query}"
    }
  }
}
