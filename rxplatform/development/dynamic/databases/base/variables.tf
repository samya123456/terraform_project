variable "environment" {
  type        = string
  description = "The environment for the database."
}

variable "namespace" {
  type        = string
  description = "The namespace for the database."
}

variable "port" {
  type        = number
  description = "The port for the database."
}

variable "database" {
  type        = string
  description = "The name of the database."
}

variable "image" {
  type        = string
  description = "The image for the database."
}

variable "args" {
  type        = list(string)
  description = "The args for the database."
  default     = null
}

variable "persistence_directory" {
  type        = string
  description = "The directory path of the persistence storage for the database."
}

variable "resources" {
  type = object({
    requests = object({
      cpu    = string
      memory = string
      disk   = string
    })
    limits = object({
      cpu    = string
      memory = string
      disk   = string
    })
  })
  description = "The resources block for the deployment."
}

variable "security_context" {
  type = object({
    run_as_user = number
    fs_group    = number
  })
  description = "The security context that the deployment should use."
  default     = null
}

variable "config" {
  type = object({
    directory = string
    secrets   = list(string)
  })
  description = "The secret configuration to inject into the database. Leave out for no configuration."
  default     = null
}

variable "environment_secrets" {
  type        = list(string)
  description = "The list of secrets to inject into the environment. Leave out for no secret injection."
  default     = []
}
