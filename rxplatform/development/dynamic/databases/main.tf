module "mongodb" {
  source      = "./mongodb"
  environment = var.environment
  namespace   = var.namespace
}

module "sql" {
  source      = "./sql"
  environment = var.environment
  namespace   = var.namespace
}

module "redis" {
  source      = "./redis"
  environment = var.environment
  namespace   = var.namespace
}

module "influxdb" {
  source      = "./influxdb"
  environment = var.environment
  namespace   = var.namespace
}

module "elasticsearch" {
  source      = "./elasticsearch"
  environment = var.environment
  namespace   = var.namespace
}
