variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "region" {
  type        = string
  description = "The region for the databases."
}

variable "database_secrets" {
  type = object({
    project_id = string
    min_size   = string
    max_size   = string
  })
  description = "Secrets for the database."
  sensitive   = true
}
