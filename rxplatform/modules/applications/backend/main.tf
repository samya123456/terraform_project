locals {
  zone                      = "rxmg-app"
  service_port              = 80
  host_prefix               = "api"
  host_suffix               = "rxmg.app"
  app                       = "backend"
  web_type                  = "web"
  queue_type                = "queue"
  scheduler_type            = "scheduler"
  google_secret_environment = coalesce(var.google_secret_environment, var.environment)
  image_environment         = coalesce(var.image_environment, var.environment)
  image_base                = "gcr.io/rxmg-infrastructure/rxplatform/backend/${local.image_environment}"
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
  roles = [
    {
      role : "storage.objectAdmin",
      conditions : [
        {
          title       = "Allow Access To ${title(var.environment)} Buckets"
          description = "Condition only allows access to the ${var.environment} buckets."
          expression  = "(resource.type == \"storage.googleapis.com/Bucket\" || resource.type == \"storage.googleapis.com/Object\") && resource.name.startsWith(\"projects/_/buckets/${var.environment}-\")"
        }
      ]
    },
    { role : "logging.viewer", conditions : [] },
    { role : "logging.logWriter", conditions : [] }
  ]
  service_account_limited_roles = [
    { role : "iam.serviceAccountTokenCreator", conditions : [] }
  ]
}

resource "kubernetes_priority_class" "web" {
  metadata {
    name = "${var.environment}-${local.app}-${local.web_type}-priority-class"
  }
  description = "Priority class for ${local.app} ${local.web_type} deployment."
  value       = 999998000
}

resource "kubernetes_priority_class" "queue" {
  metadata {
    name = "${var.environment}-${local.app}-${local.queue_type}-priority-class"
  }
  description = "Priority class for ${local.app} ${local.queue_type} deployment."
  value       = 999994000
}

resource "kubernetes_priority_class" "scheduler" {
  metadata {
    name = "${var.environment}-${local.app}-${local.scheduler_type}-priority-class"
  }
  description = "Priority class for ${local.app} ${local.scheduler_type} deployment."
  value       = 999996000
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
  container_port       = 8080
  image                = "${local.image_base}/web:latest"
  image_pull_policy    = var.image_pull_policy
  min_replicas         = var.replicas == null ? 3 : var.replicas.web.min_replicas
  max_replicas         = var.replicas == null ? 10 : var.replicas.web.max_replicas
  service_account_name = module.service_account.service_account_name
  priority_class_name  = kubernetes_priority_class.web.metadata[0].name
  resources = {
    requests = {
      cpu    = ".1"
      memory = "256Mi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
  }
  readiness_probe = {
    path = "/"
    port = 8080
  }
  application_secret  = merge(local.application_secret, { file_path : "/var/www" })
  environment_secrets = var.environment_secrets
}

module "base_queue" {
  depends_on           = [module.service_account]
  source               = "../base"
  environment          = var.environment
  type                 = local.queue_type
  host_prefix          = local.host_prefix
  host_suffix          = local.host_suffix
  app                  = local.app
  namespace            = var.namespace
  service_port         = local.service_port
  container_port       = 8080
  image                = "${local.image_base}/queue:latest"
  image_pull_policy    = var.image_pull_policy
  min_replicas         = var.replicas == null ? 5 : var.replicas.queue.min_replicas
  max_replicas         = var.replicas == null ? 15 : var.replicas.queue.max_replicas
  service_account_name = module.service_account.service_account_name
  priority_class_name  = kubernetes_priority_class.queue.metadata[0].name
  include_service      = false
  resources = {
    requests = {
      cpu    = ".5"
      memory = "2Gi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
  application_secret  = merge(local.application_secret, { file_path : "/app" })
  environment_secrets = var.environment_secrets
}

module "base_scheduler" {
  depends_on           = [module.service_account]
  source               = "../base"
  environment          = var.environment
  type                 = "scheduler"
  host_prefix          = local.host_prefix
  host_suffix          = local.host_suffix
  app                  = local.app
  namespace            = var.namespace
  service_port         = local.service_port
  container_port       = 8080
  image                = "${local.image_base}/scheduler:latest"
  image_pull_policy    = var.image_pull_policy
  min_replicas         = var.replicas == null ? 3 : var.replicas.scheduler.min_replicas
  max_replicas         = var.replicas == null ? 10 : var.replicas.scheduler.max_replicas
  service_account_name = module.service_account.service_account_name
  priority_class_name  = kubernetes_priority_class.scheduler.metadata[0].name
  include_service      = false
  resources = {
    requests = {
      cpu    = ".05"
      memory = "32Mi"
    }
    limits = {
      cpu    = "1"
      memory = "256Mi"
    }
  }
  application_secret  = merge(local.application_secret, { file_path : "/app" })
  environment_secrets = var.environment_secrets
}
