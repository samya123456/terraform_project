locals {
  job_app                   = "${var.app}-${var.type}"
  job_name                  = "${var.environment}-${var.app}-${var.type}-job"
  container_name            = "${var.environment}-${var.app}-${var.type}-container"
  application_secret_volume = "${var.environment}-${var.app}-${var.type}-env"
  application_secret_path   = "/var/www"
  application_secret_file   = ".env"
}

module "application_kubernetes_secret" {
  source                    = "../../../modules/applications/kubernetes-secret"
  environment               = var.environment
  google_secret_environment = var.google_secret_environment
  namespace                 = var.namespace
  app                       = local.job_app
  google_secret_app         = coalesce(var.alternative_app_name, var.app)
}

resource "kubernetes_job" "job" {
  metadata {
    namespace = var.namespace
    name      = local.job_name
    labels = {
      environment = var.environment
      app         = var.app
      type        = var.type
    }
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name              = local.container_name
          image             = "gcr.io/rxmg-infrastructure/rxplatform/${coalesce(var.alternative_app_name, var.app)}/${var.image_environment}/web:latest"
          command           = var.command
          args              = var.args
          image_pull_policy = var.image_pull_policy
          volume_mount {
            name       = local.application_secret_volume
            mount_path = "${local.application_secret_path}/${local.application_secret_file}"
            sub_path   = local.application_secret_file
            read_only  = true
          }
          dynamic "env_from" {
            for_each = var.environment_secrets
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
          dynamic "env" {
            for_each = var.environment_variables
            content {
              name  = env.key
              value = env.value
            }
          }
        }
        volume {
          name = local.application_secret_volume
          secret {
            secret_name = module.application_kubernetes_secret.kubernetes_secret_name
            items {
              key  = module.application_kubernetes_secret.kubernetes_secret_key
              path = local.application_secret_file
            }
          }
        }
        restart_policy = "Never"
      }
    }
  }
  wait_for_completion = true
  timeouts {
    create = var.timeout
    update = var.timeout
  }
}
