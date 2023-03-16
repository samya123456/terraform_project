locals {
  zone         = "rxmg-app"
  service_port = 80
  host_prefix  = "tabpy"
  host_suffix  = "rxmg.app"
  app          = "tabpy"
}

module "service_account" {
  source      = "../../../modules/service_account"
  environment = var.environment
  namespace   = var.namespace
  app         = local.app
  project_id  = var.project_id
  roles       = []
}

module "base_web" {
  source               = "../base"
  environment          = var.environment
  type                 = "web"
  host_prefix          = local.host_prefix
  host_suffix          = local.host_suffix
  app                  = local.app
  namespace            = var.namespace
  service_port         = local.service_port
  container_port       = 9004
  image                = "gcr.io/rxmg-infrastructure/rxp-tabpy-web-${var.environment}:v1.1.0"
  min_replicas         = 1
  max_replicas         = 4
  service_account_name = module.service_account.service_account_name
  tabpy_password       = var.tabpy_password
}
