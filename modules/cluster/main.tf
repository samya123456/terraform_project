locals {
  cluster_name        = "${var.environment}-cluster"
  node_pool_name      = "${var.environment}-node-pool"
  app                 = lookup(var.labels, "app", "")
  app_environment     = local.app == "" ? "${var.environment}" : "${local.app}-${var.environment}"
  pubsub_topic_name   = "${local.app_environment}-gke-updates"
  cloud_function_name = "${local.app_environment}-gke-updates-notifier"
  all_labels = merge(
    {
      environment = var.environment
    },
    var.labels
  )
  cluster_maintenance = {
    end_time   = "2021-11-07T14:00:00Z"
    recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    start_time = "2021-11-07T08:00:00Z"
  }
  # minimum_node_pool_service_account_roles = ["monitoring.viewer", "monitoring.metricWriter", "logging.logWriter", "stackdriver.resourceMetadata.writer"]
}

data "google_project" "project" {}

resource "google_pubsub_topic" "gke_updates" {
  name   = local.pubsub_topic_name
  labels = local.all_labels
}

data "terraform_remote_state" "general_state" {
  backend = "gcs"

  config = {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "general"
  }
}

resource "google_cloudfunctions_function" "gke_updates_notifier" {
  name    = local.cloud_function_name
  runtime = data.terraform_remote_state.general_state.outputs.cloud_functions.gke_notifier.runtime

  available_memory_mb   = data.terraform_remote_state.general_state.outputs.cloud_functions.gke_notifier.available_memory
  source_archive_bucket = data.terraform_remote_state.general_state.outputs.cloud_functions.gke_notifier.source_archive_bucket
  source_archive_object = data.terraform_remote_state.general_state.outputs.cloud_functions.gke_notifier.source_archive_object
  entry_point           = data.terraform_remote_state.general_state.outputs.cloud_functions.gke_notifier.entry_point
  environment_variables = data.terraform_remote_state.general_state.outputs.cloud_functions.gke_notifier.environment_variables
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.gke_updates.id
    failure_policy {
      retry = true
    }
  }
}

## PRIVATE CLUSTER DEPENDENCIES ##
resource "google_compute_network" "private_network" {
  count                   = var.private_configuration == null ? 0 : 1
  name                    = local.app_environment
  description             = "${trimspace("VPC network for the ${var.environment} ${var.private_configuration.vpc_display_name}")}."
  auto_create_subnetworks = true
}

resource "google_compute_subnetwork" "proxy_only_subnetwork" {
  provider      = google-beta
  count         = var.private_configuration == null ? 0 : 1
  name          = "${local.app_environment}-internal-load-balancing"
  description   = "Subnet for ${trimspace("${var.private_configuration.vpc_display_name} ${var.environment}")} internal load balancing."
  ip_cidr_range = "10.126.0.0/20"
  network       = google_compute_network.private_network[0].id
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
}

resource "google_compute_firewall" "allow_proxies" {
  count   = var.private_configuration == null ? 0 : 1
  name    = "${local.app_environment}-allow-proxies"
  network = google_compute_network.private_network[0].id

  allow {
    protocol = "tcp"
    ports    = [80, 443, 8080]
  }

  source_ranges = [google_compute_subnetwork.proxy_only_subnetwork[0].ip_cidr_range]
}

resource "google_compute_router" "cloud_router" {
  count   = var.private_configuration == null ? 0 : 1
  name    = local.app_environment
  network = google_compute_network.private_network[0].name
}

resource "google_compute_router_nat" "nat_gateway" {
  count                               = var.private_configuration == null ? 0 : 1
  name                                = local.app_environment
  router                              = google_compute_router.cloud_router[0].name
  region                              = google_compute_router.cloud_router[0].region
  min_ports_per_vm                    = 16384
  nat_ip_allocate_option              = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat  = "LIST_OF_SUBNETWORKS"
  enable_endpoint_independent_mapping = false

  subnetwork {
    name                     = local.app_environment // Autocreated by VPC resource
    secondary_ip_range_names = []
    source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
## END PRIVATE CLUSTER DEPENDENCIES ##

resource "google_container_cluster" "private_cluster" {
  provider        = google-beta
  count           = var.private_configuration == null ? 0 : 1
  name            = local.cluster_name
  location        = var.location
  resource_labels = local.all_labels
  workload_identity_config {
    identity_namespace = "${data.google_project.project.project_id}.svc.id.goog"
  }
  # We can't create a cluster with no node pool defined, but we want to only use separately managed node pools. So we create the smallest possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.private_network[0].name
  subnetwork = local.app_environment // Autocreated by VPC resource

  # enable_intranode_visibility = true # Potentially will cause issues: https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility#dns_timeouts
  enable_shielded_nodes = true

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.32/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "73.220.151.56/32"
      display_name = "Damian's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "68.202.65.125/32"
      display_name = "Kaiden's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "172.58.171.143/32"
      display_name = "Kaiden's mobile CIDR block."
    }
    cidr_blocks {
      cidr_block   = "104.34.62.51/32"
      display_name = "Javier's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "68.4.98.59/32"
      display_name = "Javier's Other CIDR block."
    }
    cidr_blocks {
      cidr_block   = "45.31.61.140/32"
      display_name = "Daniel's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "47.151.215.4/32"
      display_name = "Rudy's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "76.186.131.248/32"
      display_name = "Joshuas's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "72.207.217.51/32"
      display_name = "Charles's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "24.113.101.50/32"
      display_name = "Sarah's CIDR block."
    }
    cidr_blocks {
      cidr_block   = "35.226.22.175/32"
      display_name = "CI/CD pipeline cluster's CIDR block."
    }
  }

  ip_allocation_policy {

  }

  addons_config {
    dns_cache_config {
      enabled = true
    }
  }

  notification_config {
    pubsub {
      enabled = true
      topic   = google_pubsub_topic.gke_updates.id
    }
  }

  maintenance_policy {
    recurring_window {
      end_time   = local.cluster_maintenance.end_time
      recurrence = local.cluster_maintenance.recurrence
      start_time = local.cluster_maintenance.start_time
    }
  }
}

resource "google_container_cluster" "public_cluster" {
  provider        = google-beta
  count           = var.private_configuration == null ? 1 : 0
  name            = local.cluster_name
  location        = var.location
  resource_labels = local.all_labels
  workload_identity_config {
    identity_namespace = "${data.google_project.project.project_id}.svc.id.goog"
  }
  # We can't create a cluster with no node pool defined, but we want to only use separately managed node pools. So we create the smallest possible default node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  addons_config {
    dns_cache_config {
      enabled = true
    }
  }

  notification_config {
    pubsub {
      enabled = true
      topic   = google_pubsub_topic.gke_updates.id
    }
  }

  maintenance_policy {
    recurring_window {
      end_time   = local.cluster_maintenance.end_time
      recurrence = local.cluster_maintenance.recurrence
      start_time = local.cluster_maintenance.start_time
    }
  }
}

# resource "google_service_account" "node_pool_service_account" {
#   account_id   = local.service_account_name
#   display_name = local.service_account_display_name
#   description  = local.service_account_description
# }

# resource "google_project_iam_member" "node_pool_service_account_roles" {
#   for_each = toset(var.roles)
#   role     = "roles/${each.key}"
#   member   = "serviceAccount:${google_service_account.app_service_account.email}"
# }

resource "google_container_node_pool" "node_pool" {
  name     = local.node_pool_name
  location = var.location
  cluster  = var.private_configuration == null ? google_container_cluster.public_cluster[0].name : google_container_cluster.private_cluster[0].name

  node_count = var.min_nodes

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  node_config {
    image_type   = var.image_type
    machine_type = var.machine_type
    tags         = [var.environment]
    labels = {
      environment = var.environment
    }

    shielded_instance_config {
      enable_integrity_monitoring = var.shielded_instance_config.enable_integrity_monitoring
      enable_secure_boot          = var.shielded_instance_config.enable_secure_boot
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }


  lifecycle {
    ignore_changes = [
      node_count,             // Updated by cluster autoscaler, do not override in Terraform
      node_config[0].metadata // For some reason, ignoring the node count alone is not enough, this is also needed. Probably a bug in Terraform
    ]
  }
}
