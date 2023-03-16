output "ingress_name" {
  value       = kubernetes_ingress_v1.ingress.metadata[0].name
  description = "The name of the ingress resource."
}

output "ingress_ip" {
  value       = var.internal_configuration != null ? google_compute_address.static_ip[0].address : google_compute_global_address.static_ip[0].address
  description = "The IPv4 address of the ingress resource."
}
