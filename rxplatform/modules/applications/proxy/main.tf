locals {
  zone        = "rxmg-app"
  port        = 3306
  host_prefix = "api"
  host_suffix = "rxmg.app"
  app         = "sql"
  type        = "proxy"
  command = [
    "/cloud_sql_proxy",
    "-instances=rxmg-infrastructure:us-central1:${var.environment}=tcp:0.0.0.0:3306",
    "-use_http_health_check",
    "-term_timeout=280s",
    "-log_debug_stdout=true"
  ]
}

module "service_account" {
  source      = "../../../../modules/service_account"
  environment = var.environment
  namespace   = var.namespace
  app         = "${local.app}-proxy"
  project_id  = var.project_id
  roles = [
    {
      role : "cloudsql.client",
      conditions : [
        {
          title       = "Allow Access To ${title(var.environment)} SQL Database"
          description = "Condition only allows access to the ${var.environment} SQL database."
          expression  = "resource.type == \"sqladmin.googleapis.com/Instance\" && resource.name == \"projects/${var.project_id}/instances/${var.environment}\""
        }
      ]
    }
  ]
}

resource "kubernetes_priority_class" "sql_proxy" {
  metadata {
    name = "${local.app}-${local.type}-priority-class"
  }
  description = "Priority class for ${local.app} ${local.type} deployment."
  value       = 1000000000
}

module "base_proxy" {
  source         = "../base"
  environment    = var.environment
  type           = local.type
  host_prefix    = local.host_prefix
  host_suffix    = local.host_suffix
  app            = local.app
  namespace      = var.namespace
  service_port   = local.port
  container_port = local.port
  image          = "gcr.io/cloudsql-docker/gce-proxy:latest"
  command        = local.command
  security_context = {
    run_as_non_root = true
    run_as_user     = 65532
    run_as_group    = 65532
  }
  termination_grace_period_seconds = 300
  min_replicas                     = 3
  max_replicas                     = 10
  service_account_name             = module.service_account.service_account_name
  priority_class_name              = kubernetes_priority_class.sql_proxy.metadata[0].name
  include_service                  = true
  resources = {
    requests = {
      cpu    = ".5"
      memory = "32Mi"
    }
    limits = {
      cpu    = "1"
      memory = "256Mi"
    }
  }
  readiness_probe = {
    path = "/readiness"
    port = 8090
  }
  liveness_probe = {
    path = "/liveness"
    port = 8090
  }
  startup_probe = {
    path = "/startup"
    port = 8090
  }
}
