output "project_id" {
  description = "OCI DevOps project OCID."
  value       = oci_devops_project.wort_werk.id
}

output "project_log_group_id" {
  description = "OCI Logging log group OCID used by the DevOps project."
  value       = oci_logging_log_group.devops.id
}

output "project_log_id" {
  description = "OCI Logging service log OCID for the DevOps project."
  value       = oci_logging_log.project.id
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

output "release_handoff_bucket_name" {
  description = "Object Storage bucket name used for private rollout handoff objects."
  value       = oci_objectstorage_bucket.release_handoff.name
}

output "release_handoff_bucket_namespace" {
  description = "Object Storage namespace that owns the private rollout handoff bucket."
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "repository_url" {
  description = "Repository URL configured as the OCI DevOps build source."
  value       = var.repository_url
}

output "repository_branch" {
  description = "Default repository branch configured for OCI DevOps build stages."
  value       = var.repository_branch
}
