locals {
  namespace    = var.environment
  zone         = "rxmg-app"
  service_port = 80
  host_prefix  = "domainsilos"
  host_suffix  = "rxmg.app"
  app          = "nginx"

  labels = {
    environment = var.environment
  }
  ingress_name = "${var.environment}-ingress"

  static_ip_name               = "${var.environment}-cluster-ip"
  static_ip_description        = "Static IP for ${var.environment} cluster ingress."
  certificates_email           = "tech@rxmg.com"
  ingress_frontend_config_name = "${var.environment}-ingress-frontend-config"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = var.environment
    }
    name = local.namespace
  }
}

module "service_account" {
  source      = "../../modules/service_account"
  environment = var.environment
  namespace   = local.namespace
  app         = local.app
  project_id  = var.project_id
  roles       = []
}

module "base_web" {
  source               = "./base"
  environment          = var.environment
  type                 = "web"
  host_prefix          = local.host_prefix
  host_suffix          = local.host_suffix
  app                  = local.app
  namespace            = local.namespace
  service_port         = local.service_port
  container_port       = 80
  image                = "gcr.io/rxmg-infrastructure/domainsilos:058e0930c777f03b154c99a093de0c86a345c08b"
  min_replicas         = 2
  max_replicas         = 10
  service_account_name = module.service_account.service_account_name
  secrets              = var.secrets
}

resource "google_compute_address" "static_ip" {
  name        = local.static_ip_name
  description = local.static_ip_description
}

data "kubectl_file_documents" "nginx_controller_manifest" {
  content = templatefile("${path.module}/manifests/nginx-controller.yml", { static_ip = google_compute_address.static_ip.address })
}

resource "kubectl_manifest" "nginx_controller" {
  count = 19
  # count     = length(data.kubectl_file_documents.nginx_controller_manifest.documents) # This broke during a version, so we need to hard code it for now
  yaml_body = element(data.kubectl_file_documents.nginx_controller_manifest.documents, count.index)
}

resource "kubernetes_ingress" "ingress" {
  depends_on = [
    kubectl_manifest.nginx_controller
  ]

  lifecycle {
    ignore_changes = [spec] // Updated by CI/CD, do not override in Terraform
  }

  metadata {
    namespace = local.namespace
    name      = local.ingress_name
    labels    = local.labels
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
      "ingress.kubernetes.io/rewrite-target" : "/"
    }
  }

  spec {
    rule {
      host = "*.com"
      http {
        path {
          path = "/"
          backend {
            service_name = module.base_web.service_name
            service_port = local.service_port
          }
        }
      }
    }
  }
}

data "kubectl_file_documents" "certificate_manager_manifest" {
  content = file("${path.module}/manifests/certificate-manager.yml")
}

# TODO: This needs to have some way of depending on each former item in the list of resources. As is, you have to rerun terraform apply multiple times.
resource "kubectl_manifest" "certificate_manager" {
  count = 45
  # count     = length(data.kubectl_file_documents.certificate_manager_manifest.documents) # This broke during a version, so we need to hard code it for now
  yaml_body = element(data.kubectl_file_documents.certificate_manager_manifest.documents, count.index)
}

resource "kubectl_manifest" "certificate_issuer" {
  depends_on = [
    kubectl_manifest.certificate_manager
  ]

  yaml_body = templatefile(
    "${path.module}/manifests/certificate-cluster-issuer.yml",
    {
      environment : var.environment
      email : local.certificates_email,
    }
  )
}
