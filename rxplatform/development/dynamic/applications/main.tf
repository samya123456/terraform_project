locals {
  image_pull_policy           = "Always"
  openvpncloud_route_type     = "DOMAIN"
  intake_alternative_app_name = "incoming"
  tracking_domain             = "${var.environment}.vnt.trckng.com"
  webhook_host                = "api-${var.environment}.webhook.rxmg.app"
  migration_timeouts          = "5m"
  post_backend_standalone_jobs = {
    "run-seeders" = {
      command : ["php", "artisan", "db:seed", "RXMG\\Database\\Seeders\\DynamicEnvironmentDatabaseSeeder"]
    }
    "generate-providers" = {
      command : ["php", "artisan", "tinker", "--execute", "dump(Provider::factory(['company_id' => 2,'specification_id' => 1,])->count(10)->create())"]
    }
  }

  post_intake_standalone_jobs = {}
  post_backend_jobs = {
/*
    "generate-fake-posts" = {
      command : ["php", "artisan", "rxplatform:generate_fake_posts", module.intake.service_name, "-a", "1000"]
      environment_variables : {
        "APP_ENV" : "local"
      }
      timeout : "5m"
    }
*/
    "generate-tracking-domain" = {
      command : ["php", "artisan", "tinker", "--execute", "dump(Domain::factory()->create([\"type\" => 1, \"company_id\" => 2, \"domain\" => \"${local.tracking_domain}\"]))"]
    }
  }
  post_intake_jobs = {}
}

resource "kubernetes_secret" "global_secrets" {
  metadata {
    name      = "${var.environment}-global-secrets"
    namespace = var.namespace
  }

  data = {
    APP_ENV = var.environment
  }
}

resource "kubernetes_secret" "database_secrets" {
  metadata {
    name      = "${var.environment}-database-secrets"
    namespace = var.namespace
  }

  data = {
    DB_HOST : var.databases.sql.host
    DB_PORT : var.databases.sql.port
    DB_DATABASE : var.databases.sql.database_name
    DB_USERNAME : var.databases.sql.user
    DB_PASSWORD : var.databases.sql.password

    DATASTORE_HOST : var.databases.sql.host
    DATASTORE_PORT : var.databases.sql.port
    DATASTORE_DATABASE : var.databases.sql.datastore_database_name
    DATASTORE_USERNAME : var.databases.sql.user
    DATASTORE_PASSWORD : var.databases.sql.password

    REDIS_HOST : var.databases.redis.host
    REDIS_PASSWORD : var.databases.redis.password
    REDIS_PORT : var.databases.redis.port
    
    REDIS_CACHE_HOST : var.databases.redis.host
    REDIS_CACHE_PASSWORD : var.databases.redis.password
    REDIS_CACHE_PORT : var.databases.redis.port

    INFLUXDB_HOST : var.databases.influxdb.host
    INFLUXDB_PORT : var.databases.influxdb.port
    INFLUXDB_USER : var.databases.influxdb.user
    INFLUXDB_PASSWORD : var.databases.influxdb.password
    INFLUXDB_SSL : var.databases.influxdb.ssl
    INFLUXDB_DBNAME : var.databases.influxdb.database_name

    MONGODB_DATABASE : var.databases.mongodb.database_name
    MONGODB_DSN : var.databases.mongodb.dsn
  }
}

resource "kubernetes_secret" "intake_database_secrets" {
  metadata {
    name      = "${var.environment}-intake-database-secrets"
    namespace = var.namespace
  }

  data = {
    ELASTICSEARCH_HOST : var.databases.elasticsearch.host
    ELASTICSEARCH_PORT : var.databases.elasticsearch.port
    ELASTICSEARCH_SCHEME : var.databases.elasticsearch.scheme
    ELASTICSEARCH_USER : var.databases.elasticsearch.user
    ELASTICSEARCH_PASS : var.databases.elasticsearch.password
  }
}

module "backend_migrations" {
  source                    = "../job"
  environment               = var.environment
  namespace                 = var.namespace
  app                       = "backend"
  type                      = "migrations"
  command                   = ["php", "artisan", "migrate", "--force"]
  timeout                   = local.migration_timeouts
  google_secret_environment = var.google_secret_environment
  image_environment         = var.image_environments.backend
  image_pull_policy         = local.image_pull_policy
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name
  ]
}

module "intake_migrations" {
  depends_on = [
    module.backend_migrations
  ]
  source                    = "../job"
  environment               = var.environment
  namespace                 = var.namespace
  app                       = "intake"
  type                      = "migrations"
  command                   = ["php", "artisan", "migrate", "--force"]
  timeout                   = local.migration_timeouts
  alternative_app_name      = local.intake_alternative_app_name
  google_secret_environment = var.google_secret_environment
  image_environment         = var.image_environments.intake
  image_pull_policy         = local.image_pull_policy
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name,
    kubernetes_secret.intake_database_secrets.metadata[0].name
  ]
}

module "backend" {
  depends_on = [
    module.backend_migrations
  ]
  source                    = "../../../modules/applications/backend"
  environment               = var.environment
  image_environment         = var.image_environments.backend
  image_pull_policy         = local.image_pull_policy
  google_secret_environment = var.google_secret_environment
  namespace                 = var.namespace
  project_id                = var.project_id
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name
  ]
  replicas = {
    web = {
      min_replicas = 1
      max_replicas = 2
    },
    queue = {
      min_replicas = 1
      max_replicas = 2
    },
    scheduler = {
      min_replicas = 1
      max_replicas = 2
    }
  }

}

module "frontend" {
  source                    = "../../../modules/applications/frontend"
  environment               = var.environment
  image_environment         = var.image_environments.frontend
  image_pull_policy         = local.image_pull_policy
  google_secret_environment = var.google_secret_environment
  namespace                 = var.namespace
  project_id                = var.project_id
  environment_secrets       = [kubernetes_secret.global_secrets.metadata[0].name]
  replicas = {
    web = {
      min_replicas = 1
      max_replicas = 2
    }
  }
}

module "intake" {
  depends_on = [
    module.intake_migrations
  ]
  source                    = "../../../modules/applications/intake"
  environment               = var.environment
  image_environment         = var.image_environments.intake
  image_pull_policy         = local.image_pull_policy
  google_secret_environment = var.google_secret_environment
  namespace                 = var.namespace
  project_id                = var.project_id
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name,
    kubernetes_secret.intake_database_secrets.metadata[0].name
  ]
  replicas = {
    web = {
      min_replicas = 1
      max_replicas = 2
    },
    queue = {
      min_replicas = 1
      max_replicas = 2
    },
    scheduler = {
      min_replicas = 1
      max_replicas = 2
    }
  }
}

module "post_backend_standalone_jobs" {
  depends_on = [
    module.backend,
    module.intake
  ]
  for_each                  = local.post_backend_standalone_jobs
  source                    = "../job"
  environment               = var.environment
  namespace                 = var.namespace
  app                       = "backend"
  type                      = each.key
  command                   = each.value.command
  args                      = lookup(each.value, "args", null)
  environment_variables     = lookup(each.value, "environment_variables", {})
  timeout                   = lookup(each.value, "timeout", null)
  google_secret_environment = var.google_secret_environment
  image_environment         = var.image_environments.backend
  image_pull_policy         = local.image_pull_policy
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name
  ]
}

module "post_intake_standalone_jobs" {
  depends_on = [
    module.backend,
    module.intake
  ]
  for_each                  = local.post_intake_standalone_jobs
  source                    = "../job"
  environment               = var.environment
  namespace                 = var.namespace
  app                       = "intake"
  type                      = each.key
  command                   = each.value.command
  args                      = lookup(each.value, "args", null)
  environment_variables     = lookup(each.value, "environment_variables", {})
  timeout                   = lookup(each.value, "timeout", null)
  alternative_app_name      = local.intake_alternative_app_name
  google_secret_environment = var.google_secret_environment
  image_environment         = var.image_environments.intake
  image_pull_policy         = local.image_pull_policy
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name,
    kubernetes_secret.intake_database_secrets.metadata[0].name
  ]
}

module "post_backend_jobs" {
  depends_on = [
    module.post_backend_standalone_jobs
  ]
  for_each                  = local.post_backend_jobs
  source                    = "../job"
  environment               = var.environment
  namespace                 = var.namespace
  app                       = "backend"
  type                      = each.key
  command                   = each.value.command
  args                      = lookup(each.value, "args", null)
  environment_variables     = lookup(each.value, "environment_variables", {})
  timeout                   = lookup(each.value, "timeout", null)
  google_secret_environment = var.google_secret_environment
  image_environment         = var.image_environments.backend
  image_pull_policy         = local.image_pull_policy
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name
  ]
}

module "post_intake_jobs" {
  depends_on = [
    module.post_intake_standalone_jobs
  ]
  for_each                  = local.post_intake_jobs
  source                    = "../job"
  environment               = var.environment
  namespace                 = var.namespace
  app                       = "intake"
  type                      = each.key
  command                   = each.value.command
  args                      = lookup(each.value, "args", null)
  environment_variables     = lookup(each.value, "environment_variables", {})
  timeout                   = lookup(each.value, "timeout", null)
  alternative_app_name      = local.intake_alternative_app_name
  google_secret_environment = var.google_secret_environment
  image_environment         = var.image_environments.intake
  image_pull_policy         = local.image_pull_policy
  environment_secrets = [
    kubernetes_secret.global_secrets.metadata[0].name,
    kubernetes_secret.database_secrets.metadata[0].name,
    kubernetes_secret.intake_database_secrets.metadata[0].name
  ]
}

module "internal_ingress" {
  source                 = "../../../../modules/networking/ingress"
  environment            = var.environment
  namespace              = var.namespace
  internal_configuration = { subnetwork = var.subnetwork }
  networking = {
    (module.backend.host) = {
      zone         = module.backend.zone
      service_name = module.backend.service_name
      service_port = module.backend.service_port
      paths        = ["/*"]
    },
    (module.frontend.host) = {
      zone         = module.frontend.zone
      service_name = module.frontend.service_name
      service_port = module.frontend.service_port
      paths        = ["/*"]
    },
    (module.intake.host) = {
      zone         = module.intake.zone
      service_name = module.intake.service_name
      service_port = module.intake.service_port
      paths        = ["/*"]
    }
    (local.tracking_domain) = {
      zone         = null
      service_name = module.backend.service_name
      service_port = module.backend.service_port
      paths        = ["/*"]
    }
  }
}

# provider "openvpn-cloud" {
#   base_url      = var.openvpncloud.base_url
#   client_id     = var.openvpncloud.credentials.client_id
#   client_secret = var.openvpncloud.credentials.client_secret
# }
# Add Internal DNS Records For All Apps To VPN
resource "openvpncloud_dns_record" "backend" {
  provider = openvpn-cloud
  domain          = module.backend.host
  #description     = "RXPlatform ${var.environment} backend."
  ip_v4_addresses = [module.internal_ingress.ingress_ip]
}

resource "openvpncloud_dns_record" "frontend" {
  provider = openvpn-cloud
  domain          = module.frontend.host
  #description     = "RXPlatform ${var.environment} frontend."
  ip_v4_addresses = [module.internal_ingress.ingress_ip]
}

resource "openvpncloud_dns_record" "intake" {
  provider = openvpn-cloud
  domain          = module.intake.host
  #description     = "RXPlatform ${var.environment} intake."
  ip_v4_addresses = [module.internal_ingress.ingress_ip]
}


# Add Routes For All Apps To VPN Network
resource "openvpncloud_route" "backend" {
  provider = openvpn-cloud
  network_item_id  = var.openvpncloud_network_id
  #description = "RXPlatform ${var.environment} backend URL."
  type        = local.openvpncloud_route_type
  value       = module.backend.host
}

resource "openvpncloud_route" "frontend" {
  provider = openvpn-cloud
  network_item_id  = var.openvpncloud_network_id
  #description = "RXPlatform ${var.environment} frontend URL."
  type        = local.openvpncloud_route_type
  value       = module.frontend.host
}

resource "openvpncloud_route" "intake" {
  provider = openvpn-cloud
  network_item_id  = var.openvpncloud_network_id
  #description = "RXPlatform ${var.environment} intake URL."
  type        = local.openvpncloud_route_type
  value       = module.intake.host
}



# Add tracking domain
resource "openvpncloud_dns_record" "tracking_domain" {
  provider = openvpn-cloud
  domain          = local.tracking_domain
 # description     = "RXPlatform ${var.environment} tracking domain."
  ip_v4_addresses = [module.internal_ingress.ingress_ip]
}

 #NOTE: failing to add route
resource "openvpncloud_route" "tracking_domain" {
  provider = openvpn-cloud
  network_item_id  = var.openvpncloud_network_id
  #description = "RXPlatform ${var.environment} tracking domain URL."
  type        = local.openvpncloud_route_type
  value       = local.tracking_domain
}



module "external_webhook_ingress" {
  source      = "../../../../modules/networking/ingress"
  environment = var.environment
  namespace   = var.namespace
  networking = {
    (local.webhook_host) = {
      zone         = module.backend.zone
      service_name = module.backend.service_name
      service_port = module.backend.service_port
      paths        = ["/webhook"]
    }
  }
}
