variable "environment" {
  type        = string
  description = "The environment for the deployment."
}

variable "type" {
  type        = string
  description = "The type of deployment (ex. web) for the deployment."
  validation {
    condition     = contains(["web"], var.type)
    error_message = "Valid values for var type are (web)."
  }
}

variable "host_prefix" {
  type        = string
  description = "The hostname prefix for the app."
}

variable "host_suffix" {
  type        = string
  description = "The hostname suffix for the app."
}

variable "app" {
  type        = string
  description = "The app the deployment is managing."
}

variable "namespace" {
  type        = string
  description = "The namespace for the app."
}

variable "include_service" {
  type        = bool
  description = "Whether to add a service to expose the deployment."
  default     = true
}

variable "service_port" {
  type        = number
  description = "The port the service should listen on."
}

variable "container_port" {
  type        = number
  description = "The port the container should listen on."
}

variable "image" {
  type        = string
  description = "The image the deployment should use."
}

variable "min_replicas" {
  type        = number
  description = "The minimum number of replicas the deployment should have running."
  default     = 3
}

variable "max_replicas" {
  type        = number
  description = "The maximum number of replicas the deployment should have running."
  default     = 10
}

variable "service_account_name" {
  type        = string
  description = "The name of the service account the deployment should using."
}

variable "tabpy_password" {
  type        = string
  description = "The password for the tabpy user."
  sensitive   = true
}
