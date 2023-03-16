locals {
  app  = "rxplatform"
  type = "sql"
  labels = {
    environment = var.environment
    app         = local.app
    type        = local.type
  }
  sql_instance_name           = var.environment
  sql_database_name           = "rxplatform"
  sql_database_datastore_name = "${local.sql_database_name}_datastore"
  sql_root_user_name          = "root"
  sql_user_name               = "rxplatform"
  availability_type           = var.environment == "production" ? "REGIONAL" : "ZONAL"
}

resource "google_sql_database_instance" "sql_instance" {
  name             = local.sql_instance_name
  database_version = "MYSQL_5_7"

  settings {
    tier = "db-custom-4-26624"

    availability_type = local.availability_type

    backup_configuration {
      binary_log_enabled = true
      location           = "us"
      enabled            = true
      start_time         = "08:00"
    }

    maintenance_window {
      day  = 7
      hour = 8
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    database_flags {
      name  = "long_query_time"
      value = "1"
    }

    database_flags {
      name  = "log_output"
      value = "FILE"
    }

    user_labels = {
      app : "rxplatform"
      environment : var.environment
    }

  }
  deletion_protection = true
}

resource "google_sql_database" "rxplatform_database" {
  name     = local.sql_database_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_database" "rxplatform_datastore_database" {
  name     = local.sql_database_datastore_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_user" "root_user" {
  name     = local.sql_root_user_name
  host     = "%"
  instance = google_sql_database_instance.sql_instance.name
  password = var.database_secrets.root_password
}

resource "google_sql_user" "cloud_sql_proxy_user" {
  name     = local.sql_user_name
  host     = "cloudsqlproxy~%"
  instance = google_sql_database_instance.sql_instance.name
  password = var.database_secrets.rxplatform_password
}
