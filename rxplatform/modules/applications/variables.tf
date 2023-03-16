variable "environment" {
  type        = string
  description = "The environment for the applications."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "tracking_domains" {
  type        = list(string)
  description = "List of the tracking domains."
}
