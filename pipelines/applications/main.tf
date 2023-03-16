module "gitlab-runner" {
  source              = "./gitlab-runner"
  environment         = var.environment
  project_id          = var.project_id
  gitlab_runner_token = var.gitlab_runner_token
}
