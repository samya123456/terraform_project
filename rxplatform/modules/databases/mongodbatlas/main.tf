locals {
  cluster_name        = "rxplatform-${var.environment}"
  database_name       = "audiences"
  rxplatform_username = var.environment == "production" ? "rxplatform" : "rxplatform-${var.environment}"
  tableau_username    = var.environment == "production" ? "tableau" : "tableau-${var.environment}"
}

resource "mongodbatlas_cluster" "cluster" {
  project_id                                      = var.database_secrets.project_id
  name                                            = local.cluster_name
  cluster_type                                    = "REPLICASET"
  provider_region_name                            = "CENTRAL_US"
  cloud_backup                                    = true
  auto_scaling_disk_gb_enabled                    = true
  auto_scaling_compute_enabled                    = true
  auto_scaling_compute_scale_down_enabled         = true
  provider_auto_scaling_compute_min_instance_size = var.database_secrets.min_size
  provider_auto_scaling_compute_max_instance_size = var.database_secrets.max_size
  mongo_db_major_version                          = "4.4"
  provider_name                                   = "GCP"
  provider_instance_size_name                     = var.database_secrets.min_size

  lifecycle {
    ignore_changes = [
      provider_instance_size_name // Updated by autoscaler, do not override in Terraform
    ]
  }
}

resource "mongodbatlas_project_ip_access_list" "cidr_access" {
  project_id = var.database_secrets.project_id
  cidr_block = "0.0.0.0/0"
  comment    = "Allow all IPs."
}

resource "random_password" "rxplatform_user_password" {
  length  = 40
  special = false
}

resource "mongodbatlas_database_user" "rxplatform_user" {
  username           = local.rxplatform_username
  password           = random_password.rxplatform_user_password.result
  project_id         = var.database_secrets.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = local.database_name
  }

  labels {
    key   = "environment"
    value = var.environment
  }

  labels {
    key   = "app"
    value = "rxplatform"
  }

  scopes {
    name = mongodbatlas_cluster.cluster.name
    type = "CLUSTER"
  }
}

resource "random_password" "tableau_user_password" {
  length  = 40
  special = false
}

resource "mongodbatlas_database_user" "tableau_user" {
  username           = local.tableau_username
  password           = random_password.tableau_user_password.result
  project_id         = var.database_secrets.project_id
  auth_database_name = "admin"

  roles {
    role_name     = "read"
    database_name = local.database_name
  }

  labels {
    key   = "environment"
    value = var.environment
  }

  labels {
    key   = "app"
    value = "tableau"
  }

  scopes {
    name = mongodbatlas_cluster.cluster.name
    type = "CLUSTER"
  }
}
