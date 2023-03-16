locals {
  database      = "mongodb"
  root_user     = "root"
  user          = "rxplatform"
  database_name = "audiences"
}

resource "random_password" "user_password" {
  length  = 40
  special = false
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
    "init.js" : templatefile("${path.module}/config/init.js", { database_name : local.database_name, user : local.user, password : random_password.user_password.result })
  }
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
    MONGO_INITDB_ROOT_USERNAME : local.root_user
    MONGO_INITDB_ROOT_PASSWORD : random_password.root_password.result
  }
}

module "database" {
  source                = "../base"
  environment           = var.environment
  namespace             = var.namespace
  port                  = 27017
  database              = local.database
  image                 = "mongo"
  persistence_directory = "/data/db"
  resources = {
    requests = {
      cpu    = ".003"
      memory = "64Mi"
      disk   = "350Mi"
    }
    limits = {
      cpu    = "1"
      memory = "512Mi"
      disk   = "5Gi"
    }
  }
  config              = { directory : "/docker-entrypoint-initdb.d", secrets : [kubernetes_secret.database_config.metadata[0].name] }
  environment_secrets = [kubernetes_secret.database_secrets.metadata[0].name]
}
