locals {
  project     = "rxmg-infrastructure"
  region      = "us-central1"
  environment = "domainsilos"
  location    = "us-central1-a"
  min_nodes   = 2
  max_nodes   = 3
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "domainsilos"
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

module "cluster" {
  source       = "../modules/cluster"
  environment  = local.environment
  location     = local.location
  min_nodes    = local.min_nodes
  max_nodes    = local.max_nodes
  machine_type = "n2d-custom-2-4864"
}

# Kubernetes Provider with GCP credentials
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = module.cluster.cluster_host
  cluster_ca_certificate = module.cluster.cluster_cert
  token                  = data.google_client_config.current.access_token
}

# Same parameters as kubernetes provider
provider "kubectl" {
  load_config_file       = false
  host                   = module.cluster.cluster_host
  cluster_ca_certificate = module.cluster.cluster_cert
  token                  = data.google_client_config.current.access_token
}

module "apps" {
  # Pretty much everything in this module depends on the cluster module being completely provisioned, and not having the dependency will result in a fragmented and broken cluster state for both creation and deletion.
  # However, we might get some tiny performance gain on the non-dependent parts if we pass the dependency as a variable and into the parts that actually need it, like in this post: https://stackoverflow.com/a/58277124
  depends_on = [
    module.cluster
  ]
  source      = "./applications"
  environment = local.environment
  project_id  = local.project
  secrets     = var.secrets
}
