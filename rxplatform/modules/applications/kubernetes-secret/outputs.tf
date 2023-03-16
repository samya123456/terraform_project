output "kubernetes_secret_name" {
  value       = kubernetes_secret.application_kubernetes_secret.metadata[0].name
  description = "The name of the managed Kubernetes secret."
}

output "kubernetes_secret_key" {
  value       = local.secret_key
  description = "The key for the Kubernetes secret value."
}
