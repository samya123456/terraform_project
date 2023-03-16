locals {
  database                = "sql"
  user                    = "rxplatform"
  database_name           = "rxplatform"
  datastore_database_name = "${local.database_name}_datastore"
  init_file_name          = "init.sql"
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
    MYSQL_ROOT_PASSWORD : random_password.root_password.result
    MYSQL_USER : local.user
    MYSQL_PASSWORD : random_password.user_password.result
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
    "${local.init_file_name}" : templatefile("${path.module}/config/${local.init_file_name}", { database_name : local.database_name, datastore_database_name : local.datastore_database_name })
  }
}

module "database" {
  source                = "../base"
  environment           = var.environment
  namespace             = var.namespace
  port                  = 3306
  database              = local.database
  image                 = "mysql:5.7"
  args                  = ["--ignore-db-dir=lost+found"] # Volumes will usually have the lost+found directory on startup, so ignore it
  persistence_directory = "/var/lib/mysql"
  resources = {
    requests = {
      cpu    = ".001"
      memory = "240Mi"
      disk   = "256Mi"
    }
    limits = {
      cpu    = "1"
      memory = "1Gi"
      disk   = "5Gi"
    }
  }
  config              = { directory : "/docker-entrypoint-initdb.d", secrets : [kubernetes_secret.database_config.metadata[0].name] }
  environment_secrets = [kubernetes_secret.database_secrets.metadata[0].name]
}
