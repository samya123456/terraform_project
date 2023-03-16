output "host" {
  value       = module.base_web.host
  description = "The hostname for the app."
}

output "webhook_host" {
  value       = var.environment == "production" ? "${local.host_prefix}.webhook.${local.host_suffix}" : "${local.host_prefix}-${var.environment}.webhook.${local.host_suffix}"
  description = "The hostname for the app."
}

output "zone" {
  value       = local.zone
  description = "The domain zone for the app."
}

output "service_name" {
  value       = module.base_web.service_name
  description = "The name of the service used to expose the app."
}

output "service_port" {
  value       = local.service_port
  description = "The port the app's service runs on."
}
