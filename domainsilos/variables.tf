variable "secrets" {
  type = map(object({
    ENV_VAR_PREFIX = string
    EMAIL          = string
    PASSWORD       = string
  }))
  description = "Secrets for the domainsilo applications."
}
