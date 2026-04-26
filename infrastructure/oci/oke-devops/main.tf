provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = var.home_region
}

locals {
  stack_name                            = "wort-werk"
  topic_name                            = "${local.stack_name}-oke-devops"
  project_name                          = "${local.stack_name}-oke-release"
  log_group_name                        = "${local.stack_name}-oke-devops"
  project_log_name                      = "${local.stack_name}-oke-devops-project"
  devops_secret_read_policy_name        = "${local.stack_name}-oke-devops-secrets"
  devops_secret_read_policy_description = "Allows Wort-Werk OKE OCI DevOps resources to read the specific secrets required by the release pipeline."
  github_connection_name                = "${local.stack_name}-oke-github"
  github_push_trigger_name              = "${local.stack_name}-oke-github-push"
  build_pipeline_name                   = "${local.stack_name}-oke-build"
  deploy_pipeline_name                  = "${local.stack_name}-oke-deploy"
  build_stage_name                      = "checkout-verify-and-publish"
  trigger_deploy_stage_name             = "trigger-oke-rollout"
  shell_stage_name                      = "oke-bluegreen-rollout"
  command_spec_artifact_name            = "oke-bluegreen-command-spec"
  command_spec_artifact_display_name    = "${local.command_spec_artifact_name}-${substr(filesha256("${path.module}/command_spec.yaml"), 0, 12)}"
  build_source_name                     = "wortwerk"
  build_spec_path                       = "infrastructure/oci/oke-devops/build_spec.yaml"
  tls_ca_certificate_secret_parameter   = var.tls_ca_certificate_secret_ocid != "" ? var.tls_ca_certificate_secret_ocid : "none"
  freeform_tags = {
    group_id = local.stack_name
    tier     = "oke-devops"
  }
}

resource "oci_ons_notification_topic" "devops" {
  compartment_id = var.compartment_ocid
  name           = local.topic_name
  description    = "Notifications for Wort-Werk OKE OCI DevOps release infrastructure."
  freeform_tags  = local.freeform_tags
}

resource "oci_devops_project" "wort_werk" {
  compartment_id = var.compartment_ocid
  name           = local.project_name
  description    = "Managed OCI DevOps release project for Wort-Werk OKE blue-green rollout."

  notification_config {
    topic_id = oci_ons_notification_topic.devops.id
  }

  freeform_tags = local.freeform_tags
}

resource "oci_logging_log_group" "devops" {
  compartment_id = var.compartment_ocid
  display_name   = local.log_group_name
  description    = "OCI Logging group for Wort-Werk OKE DevOps project service logs."
  freeform_tags  = local.freeform_tags
}

resource "oci_logging_log" "project" {
  display_name       = local.project_log_name
  log_group_id       = oci_logging_log_group.devops.id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.project_log_retention_duration

  configuration {
    compartment_id = var.compartment_ocid

    source {
      category    = "all"
      resource    = oci_devops_project.wort_werk.id
      service     = "devops"
      source_type = "OCISERVICE"
    }
  }

  freeform_tags = local.freeform_tags
}

resource "oci_identity_policy" "devops_secret_read" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = local.devops_secret_read_policy_name
  description    = local.devops_secret_read_policy_description
  statements = concat([
    "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-FAMILY  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.github_connection_token_secret_ocid}'",
    "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-BUNDLES IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.github_connection_token_secret_ocid}'",
    "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-FAMILY  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.image_registry_password_secret_ocid}'",
    "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-BUNDLES IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.image_registry_password_secret_ocid}'",
    "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-FAMILY  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.runtime_db_password_secret_ocid}'",
    "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-BUNDLES IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.runtime_db_password_secret_ocid}'"
    ],
    var.tls_public_certificate_secret_ocid != ""
    ? [
      "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-FAMILY  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.tls_public_certificate_secret_ocid}'",
      "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-BUNDLES IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.tls_public_certificate_secret_ocid}'"
    ]
    : [],
    var.tls_private_key_secret_ocid != ""
    ? [
      "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-FAMILY  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.tls_private_key_secret_ocid}'",
      "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-BUNDLES IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.tls_private_key_secret_ocid}'"
    ]
    : [],
    var.tls_ca_certificate_secret_ocid != ""
    ? [
      "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-FAMILY  IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.tls_ca_certificate_secret_ocid}'",
      "ALLOW DYNAMIC-GROUP ${var.devops_dynamic_group_name} TO READ SECRET-BUNDLES IN COMPARTMENT ID ${var.compartment_ocid} WHERE target.secret.id = '${var.tls_ca_certificate_secret_ocid}'"
    ]
    : []
  )

  freeform_tags = local.freeform_tags
}

resource "oci_devops_connection" "github" {
  project_id      = oci_devops_project.wort_werk.id
  connection_type = "GITHUB_ACCESS_TOKEN"
  access_token    = var.github_connection_token_secret_ocid
  display_name    = local.github_connection_name
  description     = "GitHub connection used by the Wort-Werk OKE release pipeline."
  freeform_tags   = local.freeform_tags
}

resource "oci_devops_build_pipeline" "release" {
  project_id   = oci_devops_project.wort_werk.id
  display_name = local.build_pipeline_name
  description  = "Build pipeline that verifies, builds, and publishes a Wort-Werk OKE release image."

  build_pipeline_parameters {
    items {
      name          = "releaseVersion"
      default_value = "manual"
      description   = "Release image tag, normally set to the selected commit short SHA."
    }

    items {
      name          = "imageRepository"
      default_value = var.image_repository
      description   = "Runtime image repository without tag."
    }

    items {
      name          = "imageRegistryEndpoint"
      default_value = var.image_registry_endpoint
      description   = "Runtime image registry host."
    }

    items {
      name          = "imageRegistryUsername"
      default_value = var.image_registry_username
      description   = "Registry username used for OCI DevOps image publication and OKE pulls."
    }

    items {
      name          = "imageRegistryPasswordSecretOcid"
      default_value = var.image_registry_password_secret_ocid
      description   = "Vault secret OCID that stores the registry auth token."
    }

    items {
      name          = "okeClusterId"
      default_value = var.oke_cluster_id
      description   = "OKE cluster OCID targeted by the deploy stage."
    }

    items {
      name          = "regionRuntime"
      default_value = var.region
      description   = "OCI region used by the OKE cluster."
    }

    items {
      name          = "appBaseUrl"
      default_value = var.app_base_url
      description   = "Stable public base URL used for the post-switch smoke test."
    }

    items {
      name          = "appNamespace"
      default_value = var.app_namespace
      description   = "Stable namespace used by the blue-green rollout."
    }

    items {
      name          = "serviceType"
      default_value = var.service_type
      description   = "Kubernetes Service type used by wortwerk-active."
    }

    items {
      name          = "useNginxIngress"
      default_value = tostring(var.use_nginx_ingress)
      description   = "Whether the deploy stage should also apply the ingress manifest."
    }

    items {
      name          = "appHost"
      default_value = var.app_host
      description   = "Optional host name used by the ingress manifest."
    }

    items {
      name          = "runtimeDbUrl"
      default_value = var.runtime_db_url
      description   = "Runtime JDBC URL."
    }

    items {
      name          = "runtimeDbUsername"
      default_value = var.runtime_db_username
      description   = "Runtime database username."
    }

    items {
      name          = "runtimeDbPasswordSecretOcid"
      default_value = var.runtime_db_password_secret_ocid
      description   = "Vault secret OCID used for the runtime database password."
    }

    items {
      name          = "postgresqlDbSystemId"
      default_value = var.postgresql_db_system_id
      description   = "OCI PostgreSQL DB system OCID used to resolve the service CA certificate inside the deploy runner."
    }

    items {
      name          = "tlsPublicCertificateSecretOcid"
      default_value = var.tls_public_certificate_secret_ocid
      description   = "Vault secret OCID used for the ingress-nginx public TLS certificate."
    }

    items {
      name          = "tlsPrivateKeySecretOcid"
      default_value = var.tls_private_key_secret_ocid
      description   = "Vault secret OCID used for the ingress-nginx private TLS key."
    }

    items {
      name          = "tlsCaCertificateSecretOcid"
      default_value = local.tls_ca_certificate_secret_parameter
      description   = "Optional Vault secret OCID used for the ingress-nginx TLS CA certificate chain."
    }

    items {
      name          = "postSwitchObservationSeconds"
      default_value = tostring(var.post_switch_observation_seconds)
      description   = "Seconds to observe the public endpoint after traffic switches before deleting the previous slot."
    }

    items {
      name          = "postSwitchObservationIntervalSeconds"
      default_value = tostring(var.post_switch_observation_interval_seconds)
      description   = "Seconds between repeated public endpoint checks during post-switch observation."
    }
  }

  freeform_tags = local.freeform_tags
}

resource "oci_devops_deploy_pipeline" "release" {
  project_id   = oci_devops_project.wort_werk.id
  display_name = local.deploy_pipeline_name
  description  = "Private OKE rollout pipeline for Wort-Werk blue-green deployment."

  deploy_pipeline_parameters {
    items {
      name          = "releaseVersion"
      default_value = "manual"
      description   = "Release image tag handed off from the build pipeline."
    }

    items {
      name          = "imageRepository"
      default_value = var.image_repository
      description   = "Runtime image repository without tag."
    }

    items {
      name          = "imageRegistryEndpoint"
      default_value = var.image_registry_endpoint
      description   = "Runtime image registry host."
    }

    items {
      name          = "imageRegistryUsername"
      default_value = var.image_registry_username
      description   = "Registry username used for OKE pulls."
    }

    items {
      name          = "imageRegistryPasswordSecretOcid"
      default_value = var.image_registry_password_secret_ocid
      description   = "Vault secret OCID that stores the registry auth token."
    }

    items {
      name          = "okeClusterId"
      default_value = var.oke_cluster_id
      description   = "OKE cluster OCID targeted by the deploy stage."
    }

    items {
      name          = "regionRuntime"
      default_value = var.region
      description   = "OCI region used by the OKE cluster."
    }

    items {
      name          = "appBaseUrl"
      default_value = var.app_base_url
      description   = "Stable public base URL used for the post-switch smoke test."
    }

    items {
      name          = "appNamespace"
      default_value = var.app_namespace
      description   = "Stable namespace used by the blue-green rollout."
    }

    items {
      name          = "serviceType"
      default_value = var.service_type
      description   = "Kubernetes Service type used by wortwerk-active."
    }

    items {
      name          = "useNginxIngress"
      default_value = tostring(var.use_nginx_ingress)
      description   = "Whether the deploy stage should also apply the ingress manifest."
    }

    items {
      name          = "appHost"
      default_value = var.app_host
      description   = "Optional host name used by the ingress manifest."
    }

    items {
      name          = "runtimeDbUrl"
      default_value = var.runtime_db_url
      description   = "Runtime JDBC URL."
    }

    items {
      name          = "runtimeDbUsername"
      default_value = var.runtime_db_username
      description   = "Runtime database username."
    }

    items {
      name          = "runtimeDbPasswordSecretOcid"
      default_value = var.runtime_db_password_secret_ocid
      description   = "Vault secret OCID used for the runtime database password."
    }

    items {
      name          = "postgresqlDbSystemId"
      default_value = var.postgresql_db_system_id
      description   = "OCI PostgreSQL DB system OCID used to resolve the service CA certificate inside the deploy runner."
    }

    items {
      name          = "tlsPublicCertificateSecretOcid"
      default_value = var.tls_public_certificate_secret_ocid
      description   = "Vault secret OCID used for the ingress-nginx public TLS certificate."
    }

    items {
      name          = "tlsPrivateKeySecretOcid"
      default_value = var.tls_private_key_secret_ocid
      description   = "Vault secret OCID used for the ingress-nginx private TLS key."
    }

    items {
      name          = "tlsCaCertificateSecretOcid"
      default_value = local.tls_ca_certificate_secret_parameter
      description   = "Optional Vault secret OCID used for the ingress-nginx TLS CA certificate chain."
    }

    items {
      name          = "postSwitchObservationSeconds"
      default_value = tostring(var.post_switch_observation_seconds)
      description   = "Seconds to observe the public endpoint after traffic switches before deleting the previous slot."
    }

    items {
      name          = "postSwitchObservationIntervalSeconds"
      default_value = tostring(var.post_switch_observation_interval_seconds)
      description   = "Seconds between repeated public endpoint checks during post-switch observation."
    }
  }

  freeform_tags = local.freeform_tags
}

resource "terraform_data" "command_spec_hash" {
  input = filesha256("${path.module}/command_spec.yaml")
}

resource "oci_devops_deploy_artifact" "command_spec" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "COMMAND_SPEC"
  project_id                 = oci_devops_project.wort_werk.id
  display_name               = local.command_spec_artifact_display_name
  description                = "Shell stage command specification for the private Wort-Werk OKE rollout path."

  deploy_artifact_source {
    deploy_artifact_source_type = "INLINE"
    base64encoded_content       = filebase64("${path.module}/command_spec.yaml")
  }

  lifecycle {
    # OCI reads this field back decoded even though the API expects base64 input,
    # which otherwise causes a perpetual no-op diff after every apply.
    create_before_destroy = true
    ignore_changes        = [deploy_artifact_source[0].base64encoded_content]
    replace_triggered_by  = [terraform_data.command_spec_hash]
  }

  freeform_tags = local.freeform_tags
}

resource "oci_devops_build_pipeline_stage" "build" {
  build_pipeline_id                  = oci_devops_build_pipeline.release.id
  build_pipeline_stage_type          = "BUILD"
  display_name                       = local.build_stage_name
  description                        = "Checks out an explicit git revision, verifies the release candidate, and publishes the OKE runtime image."
  image                              = var.build_runner_image
  build_spec_file                    = local.build_spec_path
  primary_build_source               = local.build_source_name
  stage_execution_timeout_in_seconds = 3600

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.release.id
    }
  }

  build_source_collection {
    items {
      name            = local.build_source_name
      connection_type = "GITHUB"
      connection_id   = oci_devops_connection.github.id
      repository_url  = var.repository_url
      branch          = var.repository_branch
    }
  }

  private_access_config {
    network_channel_type = "SERVICE_VNIC_CHANNEL"
    subnet_id            = var.devops_subnet_id
    nsg_ids              = [var.devops_nsg_id]
  }

  freeform_tags = local.freeform_tags
}

resource "oci_devops_build_pipeline_stage" "trigger_oke_rollout" {
  build_pipeline_id              = oci_devops_build_pipeline.release.id
  build_pipeline_stage_type      = "TRIGGER_DEPLOYMENT_PIPELINE"
  display_name                   = local.trigger_deploy_stage_name
  description                    = "Triggers the private OKE rollout pipeline after the runtime image is published."
  deploy_pipeline_id             = oci_devops_deploy_pipeline.release.id
  is_pass_all_parameters_enabled = true

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build.id
    }
  }

  freeform_tags = local.freeform_tags
}

resource "oci_devops_trigger" "github_push" {
  project_id     = oci_devops_project.wort_werk.id
  trigger_source = "GITHUB"
  connection_id  = oci_devops_connection.github.id
  display_name   = local.github_push_trigger_name
  description    = "Starts the Wort-Werk OKE release pipeline for trunk pushes that affect application/runtime paths."
  freeform_tags  = local.freeform_tags

  actions {
    type              = "TRIGGER_BUILD_PIPELINE"
    build_pipeline_id = oci_devops_build_pipeline.release.id

    filter {
      trigger_source = "GITHUB"
      events         = ["PUSH"]

      include {
        head_ref = var.repository_branch
      }

      exclude {
        file_filter {
          file_paths = [
            "docs/**",
            "infrastructure/**"
          ]
        }
      }
    }
  }
}

resource "oci_devops_deploy_stage" "oke_bluegreen_rollout" {
  deploy_pipeline_id              = oci_devops_deploy_pipeline.release.id
  deploy_stage_type               = "SHELL"
  display_name                    = local.shell_stage_name
  description                     = "Private shell stage for OKE blue-green deployment inside OCI networking."
  command_spec_deploy_artifact_id = oci_devops_deploy_artifact.command_spec.id
  timeout_in_seconds              = 3600
  is_debug_enabled                = false

  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.release.id
    }
  }

  container_config {
    container_config_type = "CONTAINER_INSTANCE_CONFIG"
    compartment_id        = var.compartment_ocid
    shape_name            = var.shell_stage_shape_name

    shape_config {
      ocpus         = var.shell_stage_shape_ocpus
      memory_in_gbs = var.shell_stage_shape_memory_in_gbs
    }

    network_channel {
      network_channel_type = "SERVICE_VNIC_CHANNEL"
      subnet_id            = var.devops_subnet_id
      nsg_ids              = [var.devops_nsg_id]
    }
  }

  freeform_tags = local.freeform_tags
}
