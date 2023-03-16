locals {
  host = "${var.host_prefix}.${var.host_suffix}"
  labels = {
    environment = var.environment
    app         = var.app
    type        = var.type
  }
  secret_name                    = "${var.environment}-${var.app}-${var.type}-secret"
  secret_key                     = "tabpy_password"
  container_name                 = "${var.environment}-${var.app}-${var.type}-container"
  deployment_name                = "${var.environment}-${var.app}-${var.type}-deployment"
  service_name                   = "${var.environment}-${var.app}-${var.type}-service"
  network_policy_name            = "${var.environment}-${var.app}-${var.type}-network-policy"
  horizontal_pod_autoscaler_name = "${var.environment}-${var.app}-${var.type}-hpa"
  pod_disruption_budget_name     = "${var.environment}-${var.app}-${var.type}-pdb"
  service_type                   = "NodePort"
}


resource "kubernetes_secret" "tabpy_secret_password" {
  metadata {
    namespace = var.namespace
    name      = local.secret_name
    labels    = local.labels
  }

  data = {
    (local.secret_key) = var.tabpy_password
  }
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    namespace = var.namespace
    name      = local.deployment_name
    labels    = local.labels
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        host_network         = false
        service_account_name = var.service_account_name
        container {
          name  = local.container_name
          image = var.image
          env {
            name = "TABPY_PASSWORD"
            value_from {
              secret_key_ref {
                name = local.secret_name
                key  = local.secret_key
              }
            }
          }
          port {
            container_port = var.container_port
          }
          security_context {
            run_as_non_root = true
            run_as_user     = 1000
            privileged      = false
          }
          resources {
            requests = {
              cpu    = "1"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].replicas // Updated by HPA, do not override in Terraform
    ]
  }
}

resource "kubernetes_service" "service" {
  count = var.include_service ? 1 : 0
  metadata {
    namespace = var.namespace
    name      = local.service_name
    labels    = local.labels
  }
  spec {
    type     = local.service_type
    selector = local.labels
    port {
      port        = var.service_port
      target_port = var.container_port
    }
  }
}

resource "kubernetes_network_policy" "network_policy" {
  metadata {
    namespace = var.namespace
    name      = local.network_policy_name
    labels    = local.labels
  }

  spec {
    pod_selector {
      match_labels = local.labels
    }
    policy_types = ["Egress"]
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
  metadata {
    namespace = var.namespace
    name      = local.horizontal_pod_autoscaler_name
    labels    = local.labels
  }

  spec {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    scale_target_ref {
      kind        = "Deployment"
      name        = local.deployment_name
      api_version = "apps/v1"
    }
  }
}

resource "kubernetes_pod_disruption_budget" "pod_disruption_budget" {
  metadata {
    namespace = var.namespace
    name      = local.pod_disruption_budget_name
    labels    = local.labels
  }

  spec {
    min_available = max(1, var.min_replicas - 1)
    selector {
      match_labels = local.labels
    }
  }
}
