locals {
  project          = "rxmg-infrastructure"
  region           = "us-central1"
  location         = "us-central1"
  base_environment = "dynamic"
  branch_environment_mappings = {
    develop             = "qa"
    staging             = "staging"
    production          = "production"
    var.frontend_branch = var.frontend_branch
    var.backend_branch  = var.backend_branch

  }
  image_environments = {
    backend  = lookup(local.branch_environment_mappings, lower(var.backend_branch), "${local.base_environment}/${lower(var.backend_branch)}")
    frontend = lookup(local.branch_environment_mappings, lower(var.frontend_branch), "${local.base_environment}/${lower(var.frontend_branch)}")
    intake   = lookup(local.branch_environment_mappings, lower(var.intake_branch), "${local.base_environment}/${lower(var.intake_branch)}")
  }
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "rxplatform/development/dynamic"
  }
}

data "terraform_remote_state" "development_state" {
  backend = "gcs"

  config = {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "rxplatform/development"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

provider "openvpn-cloud" {
  base_url      = var.openvpncloud.base_url
  client_id     = var.openvpncloud.credentials.client_id
  client_secret = var.openvpncloud.credentials.client_secret
}

# Kubernetes Provider with GCP credentials
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = data.terraform_remote_state.development_state.outputs.cluster_host
  cluster_ca_certificate = data.terraform_remote_state.development_state.outputs.cluster_cert
  token                  = data.google_client_config.current.access_token
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = terraform.workspace
    }
    name = terraform.workspace
  }
}

module "buckets" {
  source      = "../../modules/buckets"
  environment = terraform.workspace
}

module "databases" {
  source      = "./databases"
  environment = terraform.workspace
  namespace   = kubernetes_namespace.namespace.metadata[0].name
}

module "apps" {
  source                    = "./applications"
  environment               = terraform.workspace
  namespace                 = kubernetes_namespace.namespace.metadata[0].name
  project_id                = local.project
  databases                 = module.databases
  image_environments        = local.image_environments
  google_secret_environment = local.base_environment
  subnetwork                = data.terraform_remote_state.development_state.outputs.cluster_subnetwork
  openvpncloud_network_id   = data.terraform_remote_state.development_state.outputs.openvpncloud_network_id
}
