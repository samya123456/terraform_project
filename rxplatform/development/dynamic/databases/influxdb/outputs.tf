output "host" {
  value       = module.database.service_name
  description = "The host for the database."
}

output "port" {
  value       = module.database.service_port
  description = "The port for the database."
}

output "database_name" {
  value       = local.database_name
  description = "The database name for the InfluxDB instance."
}

output "user" {
  value       = local.user
  description = "The user for the database."
}

output "password" {
  value       = random_password.user_password.result
  description = "The password for the database user."
}

output "ssl" {
  value       = local.ssl
  description = "The SSL setting for the database."
}
