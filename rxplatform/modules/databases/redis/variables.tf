variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "region" {
  type        = string
  description = "The region for the databases."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "database_secrets" {
  type = object({
    password = string
  })
  description = "Secrets for the database."
  sensitive   = true
}
