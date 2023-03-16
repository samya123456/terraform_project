locals {
  database         = "redis"
  config_directory = "/usr/local/etc/redis/"
  config_file_name = "redis.conf"
}

resource "random_password" "user_password" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "database_secrets" {
  metadata {
    namespace = var.namespace
    name      = "${var.environment}-${local.database}-environment-secrets"
    labels = {
      environment = var.environment
      app         = local.database
    }
  }

  data = {
    REDIS_PASSWORD : random_password.user_password.result
  }
}

resource "kubernetes_secret" "database_config" {
  metadata {
    namespace = var.namespace
    name      = "${var.environment}-${local.database}-config"
    labels = {
      environment = var.environment
      app         = local.database
    }
  }

  data = {
    "${local.config_file_name}" : file("${path.module}/config/${local.config_file_name}")
  }
}

module "database" {
  source                = "../base"
  environment           = var.environment
  namespace             = var.namespace
  port                  = 6379
  database              = local.database
  image                 = "redislabs/rebloom"
  args                  = ["${local.config_directory}/${local.config_file_name}", "--requirepass $(REDIS_PASSWORD)"]
  persistence_directory = "/data"
  resources = {
    requests = {
      cpu    = ".005"
      memory = "1.3Gi"
      disk   = "2Mi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
      disk   = "512Mi"
    }
  }
  config              = { directory : local.config_directory, secrets : [kubernetes_secret.database_config.metadata[0].name] }
  environment_secrets = [kubernetes_secret.database_secrets.metadata[0].name]
}
