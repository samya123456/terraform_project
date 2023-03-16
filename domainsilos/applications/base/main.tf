locals {
  host = var.environment == "domainsilos" ? "${var.host_prefix}.${var.host_suffix}" : "${var.host_prefix}-${var.environment}.${var.host_suffix}"
  labels = {
    environment = var.environment
    app         = var.app
    type        = var.type
  }
  container_name                 = "${var.environment}-${var.app}-${var.type}-container"
  deployment_name                = "${var.environment}-${var.app}-${var.type}-deployment"
  service_name                   = "${var.environment}-${var.app}-${var.type}-service"
  service_type                   = "NodePort"
  horizontal_pod_autoscaler_name = "${var.environment}-${var.app}-${var.type}-hpa"
  pod_disruption_budget_name     = "${var.environment}-${var.app}-${var.type}-pdb"
}

resource "kubernetes_secret" "domain_silo_secrets" {
  for_each = var.secrets
  metadata {
    namespace = var.namespace
    name      = replace("${var.environment}-${var.app}-${var.type}-${each.key}-secret", "_", "-")
    labels    = local.labels
  }

  data = each.value
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
        service_account_name = var.service_account_name

        volume {
          name = "sites"
          empty_dir {

          }
        }

        container {
          name  = local.container_name
          image = var.image
          volume_mount {
            name       = "sites"
            mount_path = "/usr/local/share/sites"
          }
          port {
            container_port = var.container_port
          }
          resources {
            requests = {
              cpu    = ".1"
              memory = "32Mi"
            }
            limits = {
              "cpu"    = "3"
              "memory" = "128Mi"
            }
          }
          lifecycle {
            post_start {
              exec {
                command = ["/bin/sh", "-c", "cp -r /var/www/html/* /usr/local/share/sites"]
              }
            }
          }
        }

        container {
          name  = "php-fpm-container"
          image = "php:7.2-fpm"
          volume_mount {
            name       = "sites"
            mount_path = "/var/www/html/"
            read_only  = true
          }
          resources {
            requests = {
              cpu    = ".1"
              memory = "32Mi"
            }
            limits = {
              "cpu"    = "3"
              "memory" = "128Mi"
            }
          }
          dynamic "env" {
            for_each = var.secrets
            content {
              name = "${env.value.ENV_VAR_PREFIX}EMAIL"
              value_from {
                secret_key_ref {
                  name = replace("${var.environment}-${var.app}-${var.type}-${env.key}-secret", "_", "-")
                  key  = "EMAIL"
                }
              }
            }
          }
          dynamic "env" {
            for_each = var.secrets
            content {
              name = "${env.value.ENV_VAR_PREFIX}PASSWORD"
              value_from {
                secret_key_ref {
                  name = replace("${var.environment}-${var.app}-${var.type}-${env.key}-secret", "_", "-")
                  key  = "PASSWORD"
                }
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].image, // Updated by CI/CD pipeline, do not override in Terraform
      spec[0].replicas                                // Updated by HPA, do not override in Terraform
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
