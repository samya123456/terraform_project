locals {
  app  = "rxplatform"
  type = "redis"
  labels = {
    environment = var.environment
    app         = local.app
    type        = local.type
  }

  provider                      = "GCP"
  redis_subscription_name       = var.environment
  redis_database_name           = var.environment
  redis_backup_bucket_name      = "${var.environment}-redis-backups"
  app_environment               = "rxplatform-${var.environment}"
  persistent_storage_encryption = var.environment == "staging" ? false : true # False only because initial staging subscription was set to false - requires replacement to change
  memory_limit_in_gb            = var.environment != "staging" ? 16 : 50      # This is what is currently in place
  database_replication          = var.environment == "qa" ? false : true
}

resource "google_storage_bucket" "redis_backups" {
  name                        = local.redis_backup_bucket_name
  labels                      = local.labels
  uniform_bucket_level_access = true
  force_destroy               = true
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

resource "rediscloud_subscription" "redis" {
  name                          = local.redis_subscription_name
  persistent_storage_encryption = local.persistent_storage_encryption

  cloud_provider {
    provider         = local.provider
    cloud_account_id = "1"
    region {
      region                       = var.region
      networking_deployment_cidr   = "192.168.0.0/24"
      preferred_availability_zones = []
    }
  }

  database {
    name                         = local.redis_database_name
    protocol                     = "redis"
    memory_limit_in_gb           = local.memory_limit_in_gb
    data_persistence             = "snapshot-every-1-hour"
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = 25000
    password                     = var.database_secrets.password
    replication                  = local.database_replication
    module {
      name = "RedisBloom"
    }

    alert {
      name  = "dataset-size"
      value = 80
    }

    alert {
      name  = "latency"
      value = 100
    }

    alert {
      name  = "syncsource-error"
      value = 1
    }

    alert {
      name  = "syncsource-lag"
      value = 600
    }

    alert {
      name  = "throughput-higher-than"
      value = 5000
    }

    alert {
      name  = "throughput-lower-than"
      value = 10
    }
  }
}

resource "rediscloud_subscription_peering" "redis_peering" {
  subscription_id  = rediscloud_subscription.redis.id
  provider_name    = local.provider
  gcp_project_id   = var.project_id
  gcp_network_name = local.app_environment
}

resource "google_compute_network_peering" "application_peering" {
  name         = "${local.app_environment}-redis-peer"
  network      = "https://www.googleapis.com/compute/v1/projects/rxmg-infrastructure/global/networks/${local.app_environment}"
  peer_network = "https://www.googleapis.com/compute/v1/projects/${rediscloud_subscription_peering.redis_peering.gcp_redis_project_id}/global/networks/${rediscloud_subscription_peering.redis_peering.gcp_redis_network_name}"
}
