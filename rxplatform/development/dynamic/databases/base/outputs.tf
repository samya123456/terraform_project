output "service_name" {
  value       = local.service_name
  description = "The name of the service used to expose the app."
}

output "service_port" {
  value       = var.port
  description = "The port the app's service runs on."
}
