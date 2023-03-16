locals {
  zone                      = "rxmg-app"
  service_port              = 80
  host_prefix               = "dashboard"
  host_suffix               = "rxmg.app"
  app                       = "frontend"
  web_type                  = "web"
  google_secret_environment = coalesce(var.google_secret_environment, var.environment)
  image_environment         = coalesce(var.image_environment, var.environment)
  image_base                = "gcr.io/rxmg-infrastructure/rxplatform/frontend/${local.image_environment}"
  application_secret = {
    file_name   = ".env"
    secret_name = module.application_kubernetes_secret.kubernetes_secret_name
    secret_key  = module.application_kubernetes_secret.kubernetes_secret_key
  }
}

module "service_account" {
  source      = "../../../../modules/service_account"
  environment = var.environment
  namespace   = var.namespace
  app         = local.app
  project_id  = var.project_id
  roles       = []
}

resource "kubernetes_priority_class" "web" {
  metadata {
    name = "${var.environment}-${local.app}-${local.web_type}-priority-class"
  }
  description = "Priority class for ${local.app} ${local.web_type} deployment."
  value       = 999997000
}

module "application_kubernetes_secret" {
  source                    = "../kubernetes-secret"
  environment               = var.environment
  google_secret_environment = local.google_secret_environment
  namespace                 = var.namespace
  app                       = local.app
}

module "base_web" {
  depends_on           = [module.service_account]
  source               = "../base"
  environment          = var.environment
  type                 = local.web_type
  host_prefix          = local.host_prefix
  host_suffix          = local.host_suffix
  app                  = local.app
  namespace            = var.namespace
  service_port         = local.service_port
  container_port       = 3000
  image                = "${local.image_base}/web:latest"
  image_pull_policy    = var.image_pull_policy
  min_replicas         = var.replicas == null ? 3 : var.replicas.web.min_replicas
  max_replicas         = var.replicas == null ? 10 : var.replicas.web.max_replicas
  service_account_name = module.service_account.service_account_name
  priority_class_name  = kubernetes_priority_class.web.metadata[0].name
  resources = {
    requests = {
      cpu    = ".05"
      memory = "256Mi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
  readiness_probe = {
    path = "/login"
    port = 3000
  }
  application_secret  = merge(local.application_secret, { file_path : "/app" })
  environment_secrets = var.environment_secrets
}
