variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "secrets" {
  type = map(object({
    ENV_VAR_PREFIX = string
    EMAIL          = string
    PASSWORD       = string
  }))
  description = "Secrets for the domainsilo applications."
}
