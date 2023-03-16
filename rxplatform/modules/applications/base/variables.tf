variable "environment" {
  type        = string
  description = "The environment for the deployment."
}

variable "type" {
  type        = string
  description = "The type of deployment (ex. web, queue, scheduler) for the deployment."
  validation {
    condition     = contains(["web", "queue", "scheduler", "proxy"], var.type)
    error_message = "Valid values for var type are (web, queue, scheduler, proxy)."
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

variable "image_pull_policy" {
  type        = string
  description = "The pull policy for the deployment image."
  default     = "IfNotPresent"
}

variable "command" {
  type        = list(string)
  description = "The command the container should use on startup. Leave blank for image default."
  default     = null
}

variable "security_context" {
  type = object({
    run_as_non_root = bool
    run_as_user     = number
    run_as_group    = number
  })
  description = "The security context that the deployment should use."
  default     = null
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

variable "priority_class_name" {
  type        = string
  description = "The name of the priority class the deployment should using."
  default     = null
}

variable "resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  description = "The resources block for the deployment."
}

variable "readiness_probe" {
  type = object({
    path : string
    port : number
  })
  description = "The details for the HTTP get readiness probe check. Leave out for no probe."
  default     = null
}

variable "liveness_probe" {
  type = object({
    path : string
    port : number
  })
  description = "The details for the HTTP get liveness probe check. Leave out for no probe."
  default     = null
}

variable "startup_probe" {
  type = object({
    path : string
    port : number
  })
  description = "The details for the HTTP get startup probe check. Leave out for no probe."
  default     = null
}

variable "termination_grace_period_seconds" {
  type        = string
  description = "The number of seconds on deletion of pod to allow for a graceful shutdown before force killing the pod."
  default     = null
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

variable "environment_secrets" {
  type        = list(string)
  description = "The list of secrets to inject into the environment. Leave out for no secret injection."
  default     = []
}
