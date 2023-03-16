variable "gitlab_runner_token" {
  type        = string
  description = "The registration token for the GitLab runner."
  sensitive   = true
}
