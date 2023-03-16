locals {
  namespace          = var.environment
  certificates_email = "tech@rxmg.com"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = var.environment
    }
    name = local.namespace
  }
}

module "tabpy" {
  source         = "./tabpy"
  environment    = var.environment
  namespace      = local.namespace
  project_id     = var.project_id
  tabpy_password = var.tabpy_password
}

module "qa_pad" {
  source      = "./qa-pad"
  environment = var.environment
  namespace   = local.namespace
  project_id  = var.project_id
}

module "tableau" {
  source = "./tableau"
}

module "ingress" {
  source      = "../../modules/networking/ingress"
  environment = var.environment
  namespace   = local.namespace
  networking = {
    (module.tabpy.host) = {
      zone         = module.tabpy.zone
      service_name = module.tabpy.service_name
      service_port = module.tabpy.service_port
      paths        = ["/*"]
    },
    (module.qa_pad.host) = {
      zone         = module.qa_pad.zone
      service_name = module.qa_pad.service_name
      service_port = module.qa_pad.service_port
      paths        = ["/*"]
    }
  }
}
