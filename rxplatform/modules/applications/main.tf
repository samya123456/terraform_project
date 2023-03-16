locals {
  namespace = var.environment
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = var.environment
    }
    name = local.namespace
  }
}

module "backend" {
  source      = "./backend"
  environment = var.environment
  namespace   = kubernetes_namespace.namespace.metadata[0].name
  project_id  = var.project_id
}

module "frontend" {
  source      = "./frontend"
  environment = var.environment
  namespace   = kubernetes_namespace.namespace.metadata[0].name
  project_id  = var.project_id
}

module "intake" {
  source      = "./intake"
  environment = var.environment
  namespace   = kubernetes_namespace.namespace.metadata[0].name
  project_id  = var.project_id
}

module "proxy" {
  source      = "./proxy"
  environment = var.environment
  namespace   = kubernetes_namespace.namespace.metadata[0].name
  project_id  = var.project_id
}

module "system" {
  source = "./system"
}

module "internal_ingress" {
  source                 = "../../../modules/networking/ingress"
  environment            = var.environment
  namespace              = kubernetes_namespace.namespace.metadata[0].name
  internal_configuration = { subnetwork = "rxplatform-${var.environment}" }
  networking = {
    (module.backend.host) = {
      zone         = module.backend.zone
      service_name = module.backend.service_name
      service_port = module.backend.service_port
      paths        = ["/*"]
    },
    (module.frontend.host) = {
      zone         = module.frontend.zone
      service_name = module.frontend.service_name
      service_port = module.frontend.service_port
      paths        = ["/*"]
    }
  }
}

module "external_ingress" {
  source      = "../../../modules/networking/ingress"
  environment = var.environment
  namespace   = kubernetes_namespace.namespace.metadata[0].name
  networking = {
    (module.intake.host) = {
      zone         = module.intake.zone
      service_name = module.intake.service_name
      service_port = module.intake.service_port
      paths        = ["/*"]
    },
    (module.backend.webhook_host) = {
      zone         = module.backend.zone
      service_name = module.backend.service_name
      service_port = module.backend.service_port
      paths        = ["/webhook"]
    }
  }
}

module "tracking_domains" {
  source      = "./tracking-domains"
  environment = var.environment
  namespace   = local.namespace
  service = {
    service_name = module.backend.service_name
    service_port = module.backend.service_port
  }
  tracking_domains = var.tracking_domains
}
