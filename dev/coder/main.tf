locals {
  location  = "us-central1"
  namespace = "coder"
  app       = "coder"
  min_nodes = 1
  max_nodes = 4
  resource_labels = {
    environment = var.environment
  }
  coder_host = "coder.rxmg.app"
  ttl        = 300
}

module "cluster" {
  source       = "../../modules/cluster"
  environment  = var.environment
  location     = local.location
  min_nodes    = local.min_nodes
  max_nodes    = local.max_nodes
  machine_type = "n2d-standard-8"
  private_configuration = {
    vpc_display_name = "Coder workspaces."
  }
  labels = { app : local.app }
  // Unfortunately, the Coder CVM needs to install a kernel module, so we must disable secure boot and use the Ubuntu image type for the nodes.
  image_type = "UBUNTU_CONTAINERD"
  shielded_instance_config = {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
  }
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

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = local.resource_labels
    name   = local.namespace
  }
}

resource "random_password" "coder_admin" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "coder_admin" {
  metadata {
    namespace = local.namespace
    name      = "${var.environment}-${local.app}-admin-secret"
    labels    = local.resource_labels
  }
  data = {
    password : random_password.coder_admin.result
  }
}

resource "google_compute_global_address" "static_ip" {
  name        = "${var.environment}-${local.app}-ingress-ip"
  description = "Static IP for ${var.environment} cluster ${local.app} ingress."
}

resource "google_compute_managed_ssl_certificate" "google_ssl_certificates" {
  name        = "${var.environment}-${local.app}-global-certificate"
  description = "SSL certificate for ${local.app} used by ${var.environment} ${local.app} cluster ingress."

  managed {
    domains = [local.coder_host]
  }
}

resource "google_dns_record_set" "domain_a_record" {
  managed_zone = "rxmg-app"
  name         = "${local.coder_host}."
  type         = "A"
  rrdatas      = [google_compute_global_address.static_ip.address]
  ttl          = local.ttl
}

resource "helm_release" "coder" {
  name        = "coder"
  description = "Helm chart release for running Coder on Kubernetes."
  # repository  = "https://helm.coder.com"
  # chart       = "coder"
  # chart = "https://helm.coder.com/coder-1.9.2.tgz"
  chart = "https://helm.coder.com/coder-1.29.1.tgz"


  namespace = kubernetes_namespace.namespace.metadata[0].name

  set_sensitive {
    name  = "coderd.superAdmin.passwordSecret.name"
    value = kubernetes_secret.coder_admin.metadata[0].name
    type  = "string"
  }

  values = [
    templatefile("${path.module}/values.yaml", {
      host : local.coder_host,
      certs : google_compute_managed_ssl_certificate.google_ssl_certificates.name
      ip_name : google_compute_global_address.static_ip.name
      }
    )
  ]
}
