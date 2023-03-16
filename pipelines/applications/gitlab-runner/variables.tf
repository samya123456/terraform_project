variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "namespace" {
  type        = string
  description = "The namespace for the GitLab runner."
  default     = "gitlab-runner"
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "gitlab_runner_token" {
  type        = string
  description = "The registration token for the GitLab runner."
  sensitive   = true
}
