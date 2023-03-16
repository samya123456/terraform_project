output "host" {
  value       = module.database.service_name
  description = "The host for the database."
}

output "port" {
  value       = module.database.service_port
  description = "The port for the database."
}

output "scheme" {
  value       = local.scheme
  description = "The scheme for the database, such as http or https."
}

output "user" {
  value       = local.user
  description = "The user for the database."
}

output "password" {
  value       = random_password.user_password.result
  description = "The password for the database user."
}
