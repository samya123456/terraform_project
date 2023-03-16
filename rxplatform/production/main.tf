locals {
  project     = "rxmg-infrastructure"
  region      = "us-central1"
  environment = "production"
  location    = "us-central1"
  min_nodes   = 2
  max_nodes   = 5
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "rxplatform/production"
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

provider "rediscloud" {
  api_key    = var.rediscloud.credentials.api_key
  secret_key = var.rediscloud.credentials.secret_key
}

provider "mongodbatlas" {
  public_key  = var.mongodbatlas.credentials.public_key
  private_key = var.mongodbatlas.credentials.private_key
}

module "cluster" {
  source       = "../../modules/cluster"
  environment  = local.environment
  location     = local.location
  min_nodes    = local.min_nodes
  max_nodes    = local.max_nodes
  machine_type = "n2d-custom-4-8192"
  private_configuration = {
    vpc_display_name = "RXPlatform"
  }
  labels = { app : "rxplatform" }
}

module "buckets" {
  source      = "../modules/buckets"
  environment = local.environment
}

module "databases" {
  source           = "../modules/databases"
  environment      = local.environment
  region           = local.region
  project_id       = local.project
  database_secrets = var.database_secrets
}

# Kubernetes Provider with GCP credentials
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = module.cluster.cluster_host
  cluster_ca_certificate = module.cluster.cluster_cert
  token                  = data.google_client_config.current.access_token
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.cluster_host
    cluster_ca_certificate = module.cluster.cluster_cert
    token                  = data.google_client_config.current.access_token
  }
}

module "apps" {
  # Pretty much everything in this module depends on the cluster module being completely provisioned, and not having the dependency will result in a fragmented and broken cluster state for both creation and deletion.
  # However, we might get some tiny performance gain on the non-dependent parts if we pass the dependency as a variable and into the parts that actually need it, like in this post: https://stackoverflow.com/a/58277124
  depends_on = [
    module.cluster
  ]
  source           = "../modules/applications"
  environment      = local.environment
  project_id       = local.project
  tracking_domains = var.tracking_domains
}

module "datadog" {
  source          = "../modules/datadog"
  environment     = local.environment
  datadog_api_key = var.datadog_api_key
  cluster_name    = module.cluster.cluster_name
}
