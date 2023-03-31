locals {
  secret_name                      = "${var.environment}-${var.app}-secret"
  service_account_name             = "${var.environment}-${var.app}-sa"
  service_account_display_name     = "${title(var.environment)} ${title(var.app)} Service Account"
  service_account_description      = "Service account used by the ${var.environment} ${var.app} app."
  service_account_iam_binding_role = "roles/iam.workloadIdentityUser"
  kubernetes_service_account_name  = "${var.environment}-${var.app}-kubernetes-sa"

  timeout = "2m"
  automount_service_account_token = true
}

resource "google_service_account" "app_service_account" {
  account_id   = local.service_account_name
  display_name = local.service_account_display_name
  description  = local.service_account_description
}

resource "google_project_iam_member" "app_service_account_roles" {
  for_each = { for role in var.roles : role.role => role }
  role     = "roles/${each.value.role}"
  member   = "serviceAccount:${google_service_account.app_service_account.email}"
  dynamic "condition" {
    for_each = each.value.conditions
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_project_iam_member" "app_service_account_custom_roles" {
  for_each = { for role in var.custom_roles : role.role => role }
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.app_service_account.email}"
  dynamic "condition" {
    for_each = each.value.conditions
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

/*
resource "kubernetes_secret_v1" "sa_secret" {
  metadata {
    name = local.secret_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = "${local.kubernetes_service_account_name}"
      "kubernetes.io/service-account.namespace" = var.namespace
    }
  }

  type = "kubernetes.io/service-account-token"
  //depends_on = [kubernetes_service_account_v1.app_kubernetes_service_account]
}

resource "kubernetes_service_account_v1" "app_kubernetes_service_account" {
  metadata {
    name      = local.kubernetes_service_account_name
    namespace = var.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.app_service_account.email
    }
    labels = {
      environment = var.environment
      app         = var.app
    }
  }

  automount_service_account_token = false

  timeouts {
    create = local.timeout
  }

}
*/
resource "kubernetes_manifest" "main_secret" {
  //count = local.kubernetes_service_account_name ? 0 : 1
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Secret"
    "metadata" = {
      "name"      = local.secret_name
      "namespace" = var.namespace
      "annotations" = {
        "kubernetes.io/service-account.name" = local.kubernetes_service_account_name
        "kubernetes.io/service-account.namespace" = var.namespace
      }
    }

    "type" = "kubernetes.io/service-account-token"
  }
}

resource "kubernetes_manifest" "main_sa" {
  //count = var.use_existing_k8s_sa ? 0 : 1
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ServiceAccount"
    "metadata" = {
      "namespace" = var.namespace
      "name"      = local.kubernetes_service_account_name
      "annotations" = {
        "iam.gke.io/gcp-service-account" = google_service_account.app_service_account.email
      }
    }

    "automountServiceAccountToken" = local.automount_service_account_token
    "secrets" = [
      {
        "name" = local.secret_name
      }
    ]
  }
  depends_on = [
    kubernetes_manifest.main_secret
  ]
}



resource "google_service_account_iam_binding" "app_service_account_limited_roles" {
  for_each = { for role in var.service_account_limited_roles : role.role => role }

  service_account_id = google_service_account.app_service_account.name
  role               = "roles/${each.value.role}"

  members = [
    "serviceAccount:${google_service_account.app_service_account.email}"
  ]

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }
}

resource "google_service_account_iam_binding" "app_service_account_binding" {
  service_account_id = google_service_account.app_service_account.name
  role               = local.service_account_iam_binding_role

  members = [
    // We pass through the project id because if the cluster workload identity isn't already configured (or the cluster isn't up), the project ID in the google project data is null
    "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${local.kubernetes_service_account_name}]"
  ]
}