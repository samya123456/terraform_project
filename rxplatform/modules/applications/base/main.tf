locals {
  host = var.environment == "production" ? "${var.host_prefix}.${var.host_suffix}" : "${var.host_prefix}-${var.environment}.${var.host_suffix}"
  labels = {
    environment = var.environment
    app         = var.app
    type        = var.type
  }
  container_name                 = "${var.environment}-${var.app}-${var.type}-container"
  deployment_name                = "${var.environment}-${var.app}-${var.type}-deployment"
  service_name                   = "${var.environment}-${var.app}-${var.type}-service"
  service_type                   = "ClusterIP"
  horizontal_pod_autoscaler_name = "${var.environment}-${var.app}-${var.type}-hpa"
  pod_disruption_budget_name     = "${var.environment}-${var.app}-${var.type}-pdb"
  application_secret_volume      = "${var.environment}-${var.app}-env"
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
        priority_class_name  = var.priority_class_name
        container {
          name              = local.container_name
          image             = var.image
          command           = var.command
          image_pull_policy = var.image_pull_policy
          dynamic "security_context" {
            for_each = var.security_context != null ? [var.security_context] : []
            content {
              run_as_non_root = security_context.value.run_as_non_root
              run_as_user     = security_context.value.run_as_user
              run_as_group    = security_context.value.run_as_group
            }
          }
          dynamic "readiness_probe" {
            for_each = var.readiness_probe == null ? [] : [1]
            content {
              http_get {
                path = var.readiness_probe.path
                port = var.readiness_probe.port
              }
            }
          }
          dynamic "liveness_probe" {
            for_each = var.liveness_probe == null ? [] : [1]
            content {
              http_get {
                path = var.liveness_probe.path
                port = var.liveness_probe.port
              }
            }
          }
          dynamic "startup_probe" {
            for_each = var.startup_probe == null ? [] : [1]
            content {
              http_get {
                path = var.startup_probe.path
                port = var.startup_probe.port
              }
            }
          }
          port {
            container_port = var.container_port
          }
          dynamic "volume_mount" {
            for_each = var.application_secret == null ? [] : [var.application_secret]
            content {
              name       = local.application_secret_volume
              mount_path = "${volume_mount.value.file_path}/${volume_mount.value.file_name}"
              sub_path   = volume_mount.value.file_name
              read_only  = true
            }
          }
          resources {
            requests = {
              cpu    = var.resources.requests.cpu
              memory = var.resources.requests.memory
            }
            limits = {
              cpu    = var.resources.limits.cpu
              memory = var.resources.limits.memory
            }
          }
          dynamic "env_from" {
            for_each = var.environment_secrets
            content {
              secret_ref {
                name = env_from.value
              }
            }
          }
        }
        termination_grace_period_seconds = var.termination_grace_period_seconds
        dynamic "volume" {
          for_each = var.application_secret == null ? [] : [var.application_secret]
          content {
            name = local.application_secret_volume
            secret {
              secret_name = volume.value.secret_name
              items {
                key  = volume.value.secret_key
                path = volume.value.file_name
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

  lifecycle {
    ignore_changes = [
      metadata[0].annotations, // Updated by GKE, do not override in Terraform
    ]
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
