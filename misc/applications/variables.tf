variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "tabpy_password" {
  type        = string
  description = "The password for the tabpy user."
  sensitive   = true
}
