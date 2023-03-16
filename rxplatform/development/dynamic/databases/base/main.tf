locals {
  labels = {
    environment = var.environment
    app         = var.database
  }
  service_name                     = "${var.environment}-${var.database}-service"
  persistent_volume_claim_name     = "${var.environment}-${var.database}-pvc-claim"
  stateful_set_name                = "${var.environment}-${var.database}-stateful-set"
  stateful_set_init_container_name = "${var.environment}-${var.database}-init-container"
  stateful_set_container_name      = "${var.environment}-${var.database}-container"
  config_directory                 = var.config == null ? null : var.config.directory
}

resource "kubernetes_priority_class" "database" {
  metadata {
    name = "${var.environment}-${var.database}-priority-class"
  }
  description = "Priority class for ${var.environment} ${var.database}."
  value       = 1000000000
}

resource "kubernetes_service" "service" {
  metadata {
    namespace = var.namespace
    name      = local.service_name
    labels    = local.labels
  }
  spec {
    selector = local.labels
    port {
      port        = var.port
      target_port = var.port
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations, // Updated by GKE, do not override in Terraform
    ]
  }
}

resource "kubernetes_stateful_set" "database" {
  metadata {
    namespace = var.namespace
    name      = local.stateful_set_name
    labels    = local.labels
  }

  spec {
    pod_management_policy = "Parallel"
    replicas              = 1
    service_name          = kubernetes_service.service.metadata[0].name

    selector {
      match_labels = local.labels
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        priority_class_name = kubernetes_priority_class.database.metadata[0].name

        container {
          name              = local.stateful_set_container_name
          image             = var.image
          image_pull_policy = "IfNotPresent"
          args              = var.args

          port {
            container_port = var.port
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

          dynamic "volume_mount" {
            for_each = var.config == null ? [] : var.config.secrets
            content {
              name       = "${volume_mount.value}-volume"
              mount_path = local.config_directory
              read_only  = true
            }
          }

          volume_mount {
            name       = local.persistent_volume_claim_name
            mount_path = var.persistence_directory
          }
        }

        dynamic "security_context" {
          for_each = var.security_context != null ? [var.security_context] : []
          content {
            run_as_user = security_context.value.run_as_user
            fs_group    = security_context.value.fs_group
          }
        }

        dynamic "volume" {
          for_each = var.config == null ? [] : var.config.secrets
          content {
            name = "${volume.value}-volume"
            secret {
              secret_name = volume.value
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        namespace = var.namespace
        name      = local.persistent_volume_claim_name
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = var.resources.requests.disk
          }
          limits = {
            storage = var.resources.limits.disk
          }
        }
      }
    }
  }
}
