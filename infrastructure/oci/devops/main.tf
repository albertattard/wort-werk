provider "oci" {
  region = var.region
}

provider "oci" {
  alias  = "home"
  region = var.home_region
}

locals {
  stack_name                                  = "wort-werk"
  topic_name                                  = "${local.stack_name}-devops"
  project_name                                = "${local.stack_name}-release"
  log_group_name                              = "${local.stack_name}-devops"
  project_log_name                            = "${local.stack_name}-devops-project"
  github_connection_secret_policy_name        = "${local.stack_name}-devops-github-connection"
  github_connection_secret_policy_description = "Allow Wort-Werk OCI DevOps resources to read the GitHub external-connection token secret"
  github_connection_name                      = "${local.stack_name}-github"
  build_pipeline_name                         = "${local.stack_name}-build"
  deploy_pipeline_name                        = "${local.stack_name}-deploy"
  build_stage_name                            = "checkout-and-package"
  deliver_bundle_stage_name                   = "publish-release-bundle"
  deliver_metadata_stage_name                 = "publish-release-metadata"
  trigger_deploy_stage_name                   = "trigger-private-rollout"
  shell_stage_name                            = "private-rollout"
  release_repository_name                     = "${local.stack_name}-release-bundles"
  release_bundle_artifact_name                = "release-bundle"
  release_metadata_artifact_name              = "release-metadata"
  command_spec_artifact_name                  = "private-rollout-command-spec"
  release_bundle_path                         = "${local.stack_name}/release-bundle.tgz"
  release_metadata_path                       = "${local.stack_name}/release-metadata.env"
  build_source_name                           = "wortwerk"
  build_spec_path                             = "infrastructure/oci/devops/build_spec.yaml"
}

resource "oci_ons_notification_topic" "devops" {
  compartment_id = var.compartment_ocid
  name           = local.topic_name
  description    = "Notifications for Wort-Werk OCI DevOps release infrastructure."
}

resource "oci_devops_project" "wort_werk" {
  compartment_id = var.compartment_ocid
  name           = local.project_name
  description    = "Managed OCI DevOps release project for Wort-Werk."

  notification_config {
    topic_id = oci_ons_notification_topic.devops.id
  }
}

resource "oci_logging_log_group" "devops" {
  compartment_id = var.compartment_ocid
  display_name   = local.log_group_name
  description    = "OCI Logging group for Wort-Werk DevOps project service logs."
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
}

resource "oci_identity_policy" "github_connection_secret_read" {
  provider       = oci.home
  compartment_id = var.compartment_ocid
  name           = local.github_connection_secret_policy_name
  description    = local.github_connection_secret_policy_description
  statements = [
    "Allow dynamic-group ${var.devops_dynamic_group_name} to read secret-family in compartment id ${var.compartment_ocid} where target.secret.id = '${var.github_connection_token_secret_ocid}'",
    "Allow dynamic-group ${var.devops_dynamic_group_name} to read secret-bundles in compartment id ${var.compartment_ocid} where target.secret.id = '${var.github_connection_token_secret_ocid}'"
  ]
}

resource "oci_devops_connection" "github" {
  project_id      = oci_devops_project.wort_werk.id
  connection_type = "GITHUB_ACCESS_TOKEN"
  access_token    = var.github_connection_token_secret_ocid
  display_name    = local.github_connection_name
  description     = "GitHub connection used by the Wort-Werk release pipeline."
}

resource "oci_artifacts_repository" "release" {
  compartment_id  = var.compartment_ocid
  repository_type = "GENERIC"
  is_immutable    = false
  display_name    = local.release_repository_name
  description     = "Generic release artifacts produced by the Wort-Werk OCI DevOps build pipeline."
}

resource "oci_devops_build_pipeline" "release" {
  project_id   = oci_devops_project.wort_werk.id
  display_name = local.build_pipeline_name
  description  = "Build pipeline that packages an explicit git revision for OCI-resident rollout."

  build_pipeline_parameters {
    items {
      name          = "releaseVersion"
      default_value = "manual"
      description   = "Release artifact version, normally set to the selected commit short SHA."
    }

    items {
      name          = "tfBackendMode"
      default_value = "local-blocked"
      description   = "Must stay non-local before the private runner is allowed to execute terraform apply."
    }
  }
}

resource "oci_devops_deploy_pipeline" "release" {
  project_id   = oci_devops_project.wort_werk.id
  display_name = local.deploy_pipeline_name
  description  = "Private OCI rollout pipeline for Wort-Werk database bootstrap and runtime deployment."

  deploy_pipeline_parameters {
    items {
      name          = "releaseVersion"
      default_value = "manual"
      description   = "Release artifact version handed off from the build pipeline."
    }

    items {
      name          = "tfBackendMode"
      default_value = "local-blocked"
      description   = "Refuses apply until runtime Terraform state is migrated off a laptop-local backend."
    }

    items {
      name          = "ROLLBACK"
      default_value = "false"
      description   = "Reserved switch for future rollback behavior in the private shell stage."
    }
  }
}

resource "oci_devops_deploy_artifact" "command_spec" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "COMMAND_SPEC"
  project_id                 = oci_devops_project.wort_werk.id
  display_name               = local.command_spec_artifact_name
  description                = "Shell stage command specification for the private Wort-Werk rollout path."

  deploy_artifact_source {
    deploy_artifact_source_type = "INLINE"
    base64encoded_content       = filebase64("${path.module}/command_spec.yaml")
  }
}

resource "oci_devops_deploy_artifact" "release_bundle" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  project_id                 = oci_devops_project.wort_werk.id
  display_name               = local.release_bundle_artifact_name
  description                = "Release bundle containing the repository snapshot required by the private shell stage."

  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    repository_id               = oci_artifacts_repository.release.id
    deploy_artifact_path        = local.release_bundle_path
    deploy_artifact_version     = "$${releaseVersion}"
  }
}

resource "oci_devops_deploy_artifact" "release_metadata" {
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  project_id                 = oci_devops_project.wort_werk.id
  display_name               = local.release_metadata_artifact_name
  description                = "Commit and image metadata handed from build to private rollout."

  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    repository_id               = oci_artifacts_repository.release.id
    deploy_artifact_path        = local.release_metadata_path
    deploy_artifact_version     = "$${releaseVersion}"
  }
}

resource "oci_devops_build_pipeline_stage" "build" {
  build_pipeline_id                  = oci_devops_build_pipeline.release.id
  build_pipeline_stage_type          = "BUILD"
  display_name                       = local.build_stage_name
  description                        = "Checks out an explicit git revision and packages the private rollout bundle."
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
}

resource "oci_devops_build_pipeline_stage" "deliver_release_bundle" {
  build_pipeline_id         = oci_devops_build_pipeline.release.id
  build_pipeline_stage_type = "DELIVER_ARTIFACT"
  display_name              = local.deliver_bundle_stage_name
  description               = "Publishes the repository release bundle to the generic artifacts repository."

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build.id
    }
  }

  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.release_bundle.id
      artifact_name = local.release_bundle_artifact_name
    }
  }
}

resource "oci_devops_build_pipeline_stage" "deliver_release_metadata" {
  build_pipeline_id         = oci_devops_build_pipeline.release.id
  build_pipeline_stage_type = "DELIVER_ARTIFACT"
  display_name              = local.deliver_metadata_stage_name
  description               = "Publishes commit and image metadata for the corresponding release bundle."

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.build.id
    }
  }

  deliver_artifact_collection {
    items {
      artifact_id   = oci_devops_deploy_artifact.release_metadata.id
      artifact_name = local.release_metadata_artifact_name
    }
  }
}

resource "oci_devops_build_pipeline_stage" "trigger_private_rollout" {
  build_pipeline_id              = oci_devops_build_pipeline.release.id
  build_pipeline_stage_type      = "TRIGGER_DEPLOYMENT_PIPELINE"
  display_name                   = local.trigger_deploy_stage_name
  description                    = "Triggers the private OCI rollout pipeline after the release artifacts are published."
  deploy_pipeline_id             = oci_devops_deploy_pipeline.release.id
  is_pass_all_parameters_enabled = true

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.deliver_release_bundle.id
    }

    items {
      id = oci_devops_build_pipeline_stage.deliver_release_metadata.id
    }
  }
}

resource "oci_devops_deploy_stage" "private_rollout" {
  deploy_pipeline_id              = oci_devops_deploy_pipeline.release.id
  deploy_stage_type               = "SHELL"
  display_name                    = local.shell_stage_name
  description                     = "Private shell stage for runtime DB bootstrap and runtime rollout inside OCI networking."
  command_spec_deploy_artifact_id = oci_devops_deploy_artifact.command_spec.id
  deploy_artifact_ids = [
    oci_devops_deploy_artifact.release_bundle.id,
    oci_devops_deploy_artifact.release_metadata.id
  ]
  timeout_in_seconds = 3600
  is_debug_enabled   = false

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
}
