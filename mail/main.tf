locals {
  project     = "rxmg-infrastructure"
  region      = "us-central1"
  environment = "mail"
  type        = "consumer"
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "mail"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_storage_bucket" "mail_storage" {
  name     = "${local.type}-${local.environment}-storage"
  location = "US"
  labels = {
    app  = "consumer"
    type = "mail"
  }
  force_destroy               = false
  uniform_bucket_level_access = true
  storage_class               = "NEARLINE"
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = "60"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = "1825" // 5 years
    }
  }
}


resource "google_storage_bucket" "system_mail_backup" {
  name     = "${local.type}-${local.environment}-system-backup"
  location = "US"
  labels = {
    app  = "consumer"
    type = "mail"
  }
  force_destroy               = false
  uniform_bucket_level_access = true
  storage_class               = "NEARLINE"
  lifecycle_rule {
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = "60"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = "1825" // 5 years
    }
  }
}

resource "google_service_account" "consumer_mail_storage" {
  account_id   = "${local.type}-${local.environment}-sa"
  display_name = "${title(local.type)} ${title(local.environment)} Service Account"
  description  = "Service account for ${local.type} ${local.environment}."
}

resource "google_storage_bucket_iam_member" "consumer_mail_storage_sa" {
  bucket = google_storage_bucket.mail_storage.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.consumer_mail_storage.email}"
}

resource "google_storage_bucket_iam_member" "consumer_system_mail_storage_sa" {
  bucket = google_storage_bucket.system_mail_backup.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.consumer_mail_storage.email}"
}
