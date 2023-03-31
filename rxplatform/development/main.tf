locals {
  project                   = "rxmg-infrastructure"
  region                    = "us-central1"
  location                  = "us-central1"
  environment               = "dynamic"
  min_nodes                 = 1
  max_nodes                 = 5
  openvpncloud_network_name = "RXP-Dynamic"
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "rxplatform/development"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

provider "google-beta" {
  project = local.project
  region  = local.region
}

provider "openvpn-cloud" {
  base_url      = var.openvpncloud.base_url
  client_id     = var.openvpncloud.credentials.client_id
  client_secret = var.openvpncloud.credentials.client_secret
}

module "cluster" {
  source       = "../../modules/cluster"
  environment  = local.environment
  location     = local.location
  min_nodes    = local.min_nodes
  max_nodes    = local.max_nodes
  machine_type = "n2d-custom-4-12288"
  private_configuration = {
    vpc_display_name = "RXPlatform"
  }
  labels = { app : "rxplatform" }
}

# Kubernetes Provider with GCP credentials
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = module.cluster.cluster_host
  cluster_ca_certificate = module.cluster.cluster_cert
  token                  = data.google_client_config.current.access_token
}

module "system" {
  source = "../modules/applications/system"
}

data "openvpncloud_network" "network" {
  name = local.openvpncloud_network_name
}
