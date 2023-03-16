output "service_name" {
  value       = module.base_proxy.service_name
  description = "The name of the service used to expose the app."
}

output "service_port" {
  value       = local.port
  description = "The port the app's service runs on."
}
