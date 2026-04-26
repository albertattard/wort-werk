output "project_id" {
  description = "OCI DevOps project OCID."
  value       = oci_devops_project.wort_werk.id
}

output "build_pipeline_id" {
  description = "OCI DevOps build pipeline OCID."
  value       = oci_devops_build_pipeline.release.id
}

output "deploy_pipeline_id" {
  description = "OCI DevOps deploy pipeline OCID."
  value       = oci_devops_deploy_pipeline.release.id
}

output "github_push_trigger_id" {
  description = "OCI DevOps trigger OCID for GitHub trunk push releases."
  value       = oci_devops_trigger.github_push.id
}

output "repository_url" {
  description = "Repository URL configured as the OCI DevOps build source."
  value       = var.repository_url
}

output "repository_branch" {
  description = "Default repository branch configured for OCI DevOps build stages."
  value       = var.repository_branch
}
