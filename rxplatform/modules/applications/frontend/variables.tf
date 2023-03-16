variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "image_environment" {
  type        = string
  description = "The environment for the image. Leave blank for same as resource environment."
  default     = null
}

variable "image_pull_policy" {
  type        = string
  description = "The pull policy for the deployment image. Leave blank for default."
  default     = null
}

variable "google_secret_environment" {
  type        = string
  description = "The environment for the secret in Google Secret Manager. Leave blank for the same as the resource environment."
  default     = null
}

variable "namespace" {
  type        = string
  description = "The namespace for the app."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "environment_secrets" {
  type        = list(string)
  description = "The list of secrets to inject into the environment. Leave out for no secret injection."
  default     = []
}

variable "replicas" {
  type = object({
    web = object({
      min_replicas = string
      max_replicas = string
    })
  })
  description = "The replicas for each of the deployments. Leave out for default deployments replicas."
  default     = null
}
