locals {
  secret_key                = ".env"
  google_secret_environment = coalesce(var.google_secret_environment, var.environment)
  google_secret_app         = coalesce(var.google_secret_app, var.app)
}

data "google_secret_manager_secret_version" "application_secret" {
  secret = "${local.google_secret_app}-${local.google_secret_environment}-env"
}

resource "kubernetes_secret" "application_kubernetes_secret" {
  metadata {
    name      = "${var.environment}-${var.app}-kubernetes-env"
    namespace = var.namespace
  }

  data = {
    (local.secret_key) = data.google_secret_manager_secret_version.application_secret.secret_data
  }
}
