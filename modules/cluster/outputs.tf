output "cluster_host" {
  value       = var.private_configuration == null ? "https://${google_container_cluster.public_cluster[0].endpoint}" : "https://${google_container_cluster.private_cluster[0].endpoint}"
  description = "The cluster endpoint."
}

output "cluster_cert" {
  value       = var.private_configuration == null ? base64decode(google_container_cluster.public_cluster[0].master_auth.0.cluster_ca_certificate) : base64decode(google_container_cluster.private_cluster[0].master_auth.0.cluster_ca_certificate)
  description = "The cluster CA certificate."
}

output "subnetwork" {
  value       = var.private_configuration == null ? google_container_cluster.public_cluster[0].subnetwork : google_container_cluster.private_cluster[0].subnetwork
  description = "The cluster subnetwork."
}

output "cluster_name" {
  value       = local.cluster_name
  description = "The cluster name."
}
