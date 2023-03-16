output "host" {
  value       = module.database.service_name
  description = "The host for the database."
}

output "port" {
  value       = module.database.service_port
  description = "The port for the database."
}

output "password" {
  value       = random_password.user_password.result
  description = "The password for the database user."
}
