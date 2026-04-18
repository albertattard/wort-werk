provider "oci" {
  region = var.region
  auth   = var.oci_auth
}

locals {
  stack_name                  = "wort-werk"
  container_display_name      = local.stack_name
  load_balancer_name          = local.stack_name
  backend_set_name            = "${local.stack_name}-backend-set"
  http_listener_name          = "http"
  https_listener_name         = "https"
  http_to_https_rule_set_name = "http_to_https"
  image_url                   = "${var.image_repository}:${var.image_tag}"
  public_origin               = var.https_listener_port == 443 ? "https://${var.tls_redirect_host}" : "https://${var.tls_redirect_host}:${var.https_listener_port}"
  container_environment = merge(
    {
      WORTWERK_WEBAUTHN_RP_ID           = var.tls_redirect_host
      WORTWERK_WEBAUTHN_ALLOWED_ORIGINS = local.public_origin
      WORTWERK_BUILD_HASH               = substr(var.image_tag, 0, 7)
      MANAGEMENT_SERVER_PORT            = tostring(var.management_port)
    },
    var.runtime_db_url != "" ? {
      WORTWERK_DB_URL                  = var.runtime_db_url
      WORTWERK_DB_USERNAME             = var.runtime_db_username
      WORTWERK_DB_PASSWORD_SECRET_OCID = var.runtime_db_password_secret_ocid
      WORTWERK_DB_SSL_ROOT_CERT_BASE64 = var.runtime_db_ssl_root_cert_base64
    } : {}
  )
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

data "oci_secrets_secretbundle" "tls_public_certificate" {
  secret_id = var.tls_public_certificate_secret_ocid
}

data "oci_secrets_secretbundle" "tls_private_key" {
  secret_id = var.tls_private_key_secret_ocid
}

data "oci_secrets_secretbundle" "tls_ca_certificate" {
  count     = var.tls_ca_certificate_secret_ocid != "" ? 1 : 0
  secret_id = var.tls_ca_certificate_secret_ocid
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
    subnet_id             = var.runtime_subnet_id
    is_public_ip_assigned = false
    nsg_ids               = [var.nsg_id]
  }

  image_pull_secrets {
    secret_type       = "BASIC"
    registry_endpoint = var.image_registry_endpoint
    username          = base64encode(var.image_registry_username)
    password          = base64encode(var.image_registry_password)
  }

  containers {
    display_name                   = local.container_display_name
    image_url                      = local.image_url
    is_resource_principal_disabled = false
    environment_variables          = local.container_environment

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
  display_name               = local.load_balancer_name
  shape                      = "flexible"
  subnet_ids                 = [var.load_balancer_subnet_id]
  network_security_group_ids = [var.load_balancer_nsg_id]

  shape_details {
    minimum_bandwidth_in_mbps = var.load_balancer_min_bandwidth_mbps
    maximum_bandwidth_in_mbps = var.load_balancer_max_bandwidth_mbps
  }

  reserved_ips {
    id = var.load_balancer_public_ip_id
  }

  lifecycle {
    # OCI readback exposes the attached reserved IP through computed IP-address details
    # after import, so keeping this create-time input under drift detection forces
    # an unnecessary replacement of a healthy live load balancer.
    ignore_changes = [reserved_ips]
  }
}

resource "oci_load_balancer_backend_set" "wort_werk" {
  name             = local.backend_set_name
  load_balancer_id = oci_load_balancer_load_balancer.wort_werk.id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol    = "HTTP"
    port        = var.management_port
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
  name                     = local.http_listener_name
  default_backend_set_name = oci_load_balancer_backend_set.wort_werk.name
  port                     = var.lb_listener_port
  protocol                 = "HTTP"
  rule_set_names           = [oci_load_balancer_rule_set.http_to_https.name]
}

resource "oci_load_balancer_certificate" "wort_werk_tls" {
  certificate_name   = var.tls_certificate_name
  load_balancer_id   = oci_load_balancer_load_balancer.wort_werk.id
  public_certificate = base64decode(data.oci_secrets_secretbundle.tls_public_certificate.secret_bundle_content[0].content)
  private_key        = base64decode(data.oci_secrets_secretbundle.tls_private_key.secret_bundle_content[0].content)
  ca_certificate     = var.tls_ca_certificate_secret_ocid != "" ? base64decode(data.oci_secrets_secretbundle.tls_ca_certificate[0].secret_bundle_content[0].content) : null
}

resource "oci_load_balancer_listener" "https" {
  load_balancer_id         = oci_load_balancer_load_balancer.wort_werk.id
  name                     = local.https_listener_name
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
  name             = local.http_to_https_rule_set_name

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
