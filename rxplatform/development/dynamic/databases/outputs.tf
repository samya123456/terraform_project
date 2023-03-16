output "mongodb" {
  value = {
    dsn           = module.mongodb.dsn
    database_name = module.mongodb.database_name
  }
  description = "The database details for MongoDB."
}

output "sql" {
  value = {
    host                    = module.sql.host
    port                    = module.sql.port
    database_name           = module.sql.database_name
    datastore_database_name = module.sql.datastore_database_name
    user                    = module.sql.user
    password                = module.sql.password
  }
  description = "The database details for MySQL."
}

output "redis" {
  value = {
    host     = module.redis.host
    port     = module.redis.port
    password = module.redis.password
  }
  description = "The database details for Redis."
}

output "influxdb" {
  value = {
    host          = module.influxdb.host
    port          = module.influxdb.port
    database_name = module.influxdb.database_name
    user          = module.influxdb.user
    password      = module.influxdb.password
    ssl           = module.influxdb.ssl
  }
  description = "The database details for InfluxDB."
}

output "elasticsearch" {
  value = {
    host     = module.elasticsearch.host
    port     = module.elasticsearch.port
    scheme   = module.elasticsearch.scheme
    user     = module.elasticsearch.user
    password = module.elasticsearch.password
  }
  description = "The database details for Elasticsearch."
}
