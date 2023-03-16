output "host" {
  value = local.host
  description = "The hostname for the app."
}

output "service_name" {
  value = local.service_name
  description = "The name of the service used to expose the app."
}