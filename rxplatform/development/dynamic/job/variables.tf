variable "environment" {
  type        = string
  description = "The environment for the applications."
}

variable "namespace" {
  type        = string
  description = "The namespace for the applications."
}

variable "app" {
  type        = string
  description = "The app for the job (ex. backend)."
  validation {
    condition     = contains(["backend", "intake"], var.app)
    error_message = "Valid values for var app are (backend, intake)."
  }
}

variable "type" {
  type        = string
  description = "The type of job (ex. migration)."
}

variable "command" {
  type        = list(string)
  description = "The command for the job."
}

variable "args" {
  type        = list(string)
  description = "The args for the job. Leave blank for none."
  default     = null
}

variable "environment_variables" {
  type        = map(string)
  description = "The environment variables to set for the job. Leave blank for none."
  default     = {}
}

variable "timeout" {
  type        = string
  description = "The timeout to set for the job. Leave blank for default."
  default     = "1m"
}

variable "alternative_app_name" {
  type        = string
  description = "The alternative app name for the job (ex. incoming)."
  default     = null
}

variable "google_secret_environment" {
  type        = string
  description = "The environment for the secret in Google Secret Manager."
}

variable "image_environment" {
  type        = string
  description = "The environment for the image."
}

variable "image_pull_policy" {
  type        = string
  description = "The pull policy for the deployment image."
}

variable "environment_secrets" {
  type        = list(string)
  description = "The list of secrets to inject into the environment. Leave out for no secret injection."
  default     = []
}

variable "application_secret" {
  type = object({
    file_name   = string
    file_path   = string
    secret_name = string
    secret_key  = string
  })
  description = "The details for the application secret injection. Leave out for no secret injection."
  default     = null
}
