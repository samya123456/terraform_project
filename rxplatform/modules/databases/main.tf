locals {
  is_prod = var.environment == "production"
  is_qa   = var.environment == "qa"
}

# NOTE: InfluxDB Cloud is also used for all environments, but there is no official Terraform module for it. It is manually set up.

// TODO: LOCK DOWN AUTOMATED FIREWALL RULES
// TODO: PASS DATABASE INFO DIRECTLY TO PODS INSTEAD OF MANUALLY DOING SO THROUGH SECRET MANAGER
module "mongodb" {
  count            = local.is_prod || local.is_qa ? 0 : 1
  source           = "./mongodb"
  environment      = var.environment
  region           = var.region
  database_secrets = var.database_secrets.mongodb
}

module "mongodbatlas" {
  count            = local.is_prod || local.is_qa ? 1 : 0
  source           = "./mongodbatlas"
  environment      = var.environment
  region           = var.region
  database_secrets = var.database_secrets.mongodbatlas
}

module "sql" {
  source           = "./sql"
  environment      = var.environment
  region           = var.region
  database_secrets = var.database_secrets.sql
}

module "redis" {
  source           = "./redis"
  environment      = var.environment
  region           = var.region
  project_id       = var.project_id
  database_secrets = var.database_secrets.redis
}
