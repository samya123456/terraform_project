variable "environment" {
  type        = string
  description = "The environment for the Kubernetes secret."
}

variable "google_secret_environment" {
  type        = string
  description = "The environment for the secret in Google Secret Manager. Leave blank for the same as the Kubernetes secret."
  default     = null
}

variable "app" {
  type        = string
  description = "The app the Kubernetes secret is for."
}

variable "google_secret_app" {
  type        = string
  description = "The app for the secret in Google Secret Manager. Leave blank for the same as the Kubernetes secret."
  default     = null
}

variable "namespace" {
  type        = string
  description = "The namespace for the Kubernetes secret."
}
