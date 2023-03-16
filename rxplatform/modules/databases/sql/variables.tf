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
    root_password       = string
    rxplatform_password = string
  })
  description = "Secrets for the database."
  sensitive   = true
}
