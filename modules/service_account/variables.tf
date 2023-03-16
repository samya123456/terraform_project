variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "namespace" {
  type        = string
  description = "The namespace for the app."
}

variable "app" {
  type        = string
  description = "The app for the service account."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "roles" {
  type = list(object({
    role : string
    conditions : list(object({
      title : string
      description : string
      expression : string
    }))
  }))
  description = "The list of project wide roles object definitions for the service account."
}

variable "custom_roles" {
  type = list(object({
    role : string
    conditions : list(object({
      title : string
      description : string
      expression : string
    }))
  }))
  description = "The list of project wide custom roles object definitions for the service account."
  default     = []
}

variable "service_account_limited_roles" {
  type = list(object({
    role : string
    conditions : list(object({
      title : string
      description : string
      expression : string
    }))
  }))
  description = "The list of roles object definitions to place only on the service account."
  default     = []
}
