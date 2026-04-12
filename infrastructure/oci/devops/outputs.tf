output "project_id" {
  description = "OCI DevOps project OCID."
  value       = oci_devops_project.wort_werk.id
}

output "github_connection_id" {
  description = "OCI DevOps GitHub connection OCID."
  value       = oci_devops_connection.github.id
}

output "build_pipeline_id" {
  description = "OCI DevOps build pipeline OCID."
  value       = oci_devops_build_pipeline.release.id
}

output "deploy_pipeline_id" {
  description = "OCI DevOps deploy pipeline OCID."
  value       = oci_devops_deploy_pipeline.release.id
}

output "release_artifact_repository_id" {
  description = "Generic artifacts repository used for private rollout bundles."
  value       = oci_artifacts_repository.release.id
}

output "repository_url" {
  description = "Repository URL configured as the OCI DevOps build source."
  value       = var.repository_url
}

output "repository_branch" {
  description = "Default repository branch configured for OCI DevOps build stages."
  value       = var.repository_branch
}
