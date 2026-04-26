output "cluster_id" {
  description = "OKE cluster OCID."
  value       = oci_containerengine_cluster.wort_werk.id
}

output "cluster_name" {
  description = "OKE cluster display name."
  value       = oci_containerengine_cluster.wort_werk.name
}

output "cluster_kubernetes_version" {
  description = "Kubernetes version configured for the OKE cluster."
  value       = oci_containerengine_cluster.wort_werk.kubernetes_version
}

output "node_pool_id" {
  description = "OKE node pool OCID."
  value       = oci_containerengine_node_pool.wort_werk.id
}

output "app_namespace" {
  description = "Stable application namespace used by the blue-green rollout."
  value       = var.app_namespace
}
