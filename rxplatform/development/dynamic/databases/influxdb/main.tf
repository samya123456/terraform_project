locals {
  database      = "influxdb"
  database_name = "rxplatform"
  root_user     = "root"
  user          = "rxplatform"
  ssl           = "false"
}

resource "random_password" "user_password" {
  length  = 40
  special = false
}

resource "random_password" "root_password" {
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
    INFLUXDB_DB : local.database_name
    INFLUXDB_ADMIN_USER : local.root_user
    INFLUXDB_ADMIN_USER_PASSWORD : random_password.root_password.result
    INFLUXDB_USER : local.user
    INFLUXDB_USER_PASSWORD : random_password.user_password.result
    INFLUXDB_HTTP_AUTH_ENABLED : "true"
  }
}

module "database" {
  source                = "../base"
  environment           = var.environment
  namespace             = var.namespace
  port                  = 8086
  database              = local.database
  image                 = "influxdb:1.8"
  persistence_directory = "/var/lib/influxdb"
  resources = {
    requests = {
      cpu    = ".001"
      memory = "33Mi"
      disk   = "5Mi"
    }
    limits = {
      cpu    = "1"
      memory = "512Mi"
      disk   = "512Mi"
    }
  }
  environment_secrets = [kubernetes_secret.database_secrets.metadata[0].name]
}
