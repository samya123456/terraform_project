locals {
  project                    = "rxmg-infrastructure"
  region                     = "us-central1"
  zipped_functions_directory = "zipped_functions"
  cloud_functions = {
    gke_notifier = {
      directory = "gke_slack"
      outputs = {
        runtime          = "nodejs10"
        entry_point      = "slackNotifier"
        available_memory = 128
        environment_variables = {
          "SLACK_WEBHOOK_URL" = var.slack_webhook_url
        }
      }
    }
  }
  datadog_roles = toset(["roles/compute.viewer", "roles/monitoring.viewer", "roles/cloudasset.viewer"])
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "general"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_storage_bucket" "functions_bucket" {
  name                        = "${local.project}-cloud-functions"
  uniform_bucket_level_access = true
  force_destroy               = true
}

data "archive_file" "zip_files" {
  for_each    = local.cloud_functions
  type        = "zip"
  source_dir  = "${path.module}/functions/${each.value.directory}"
  output_path = "${path.module}/functions/${local.zipped_functions_directory}/${each.key}.zip"
}

resource "google_storage_bucket_object" "gke_slack_function_objects" {
  for_each = data.archive_file.zip_files
  name     = each.key
  bucket   = google_storage_bucket.functions_bucket.name
  source   = each.value.output_path
}

resource "google_service_account" "datadog" {
  account_id   = "datadog"
  display_name = "Datadog Service Account"
  description  = "Service account for Datadog integration."
}

resource "google_project_iam_member" "datadog_service_account_permissions" {
  for_each = local.datadog_roles
  role     = each.value

  member = "serviceAccount:${google_service_account.datadog.email}"
}

resource "google_pubsub_topic" "datadog_export" {
  name = "export-logs-to-datadog"
  labels = {
    app = "datadog"
  }
}

resource "google_pubsub_subscription" "datadog_export" {
  name  = "export-logs-to-datadog-notifier"
  topic = google_pubsub_topic.datadog_export.name

  labels = {
    app = "datadog"
  }

  push_config {
    push_endpoint = "https://gcp-intake.logs.datadoghq.com/api/v2/logs?dd-api-key=${var.datadog_api_key}&dd-protocol=gcp"
  }
}

resource "google_logging_project_sink" "datadog_export" {
  name = "export-logs-to-datadog-sink"

  destination = "pubsub.googleapis.com/${google_pubsub_topic.datadog_export.id}"

  # Log all WARN or higher severity messages relating to instances
  # filter = "resource.type = gce_instance AND severity >= WARNING"
  filter = "production NOT GoogleHC"

  exclusions {
    name        = "GKE Health Checks"
    description = "Excludes health checks for GKE."
    filter      = "GoogleHC"
  }

  # Use a unique writer (creates a unique service account used for writing)
  unique_writer_identity = true
}

resource "google_project_iam_member" "log-writer" {
  role = "roles/pubsub.publisher"

  member = google_logging_project_sink.datadog_export.writer_identity
}



resource "google_storage_bucket" "datadog_logs_archive" {
  name     = "${local.project}-datadog-logs-archive"
  location = "US"
  labels = {
    app  = "datadog"
    type = "logs"
  }
  force_destroy               = false
  uniform_bucket_level_access = true
  # storage_class               = "NEARLINE"
}

resource "google_storage_bucket_iam_member" "datadog-sa" {
  bucket = google_storage_bucket.datadog_logs_archive.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.datadog.email}"
}
