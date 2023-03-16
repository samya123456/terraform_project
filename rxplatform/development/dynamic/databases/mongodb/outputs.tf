output "dsn" {
  value       = "mongodb://${local.user}:${random_password.user_password.result}@${module.database.service_name}:${module.database.service_port}/${local.database_name}"
  description = "The port for the database."
}

output "host" {
  value       = module.database.service_name
  description = "The host for the database."
}

output "database_name" {
  value       = local.database_name
  description = "The database name for the MongoDB instance."
}

