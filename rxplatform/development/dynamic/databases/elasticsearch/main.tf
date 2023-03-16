locals {
  database = "elasticsearch"
  user     = "elastic"
  scheme   = "http"
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
    "network.host" : "0.0.0.0"
    "bootstrap.memory_lock" : "true"
    "discovery.type" : "single-node"
    "xpack.security.enabled" : "true"
    ELASTIC_PASSWORD : random_password.user_password.result
    ES_JAVA_OPTS : "-Xms256m -Xmx256m"
  }
}

module "database" {
  source                = "../base"
  environment           = var.environment
  namespace             = var.namespace
  port                  = 9200
  database              = local.database
  image                 = "elasticsearch:7.14.2"
  persistence_directory = "/usr/share/elasticsearch/data"
  security_context = {
    fs_group : 1000,
    run_as_user : 1000
  }
  resources = {
    requests = {
      cpu    = ".002"
      memory = "512Mi"
      disk   = "6Mi"
    }
    limits = {
      cpu    = "1"
      memory = "1024Mi"
      disk   = "512Mi"
    }
  }
  environment_secrets = [kubernetes_secret.database_secrets.metadata[0].name]
}
