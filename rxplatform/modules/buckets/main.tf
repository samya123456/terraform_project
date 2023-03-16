locals {
  buckets = {
    rxplatform-campaign-logs = {
      uniform_bucket_level_access = false
    },
    rxplatform-suppressions = {
      uniform_bucket_level_access = false
    },
    rxplatform-creative-assets = {
      uniform_bucket_level_access = false
    },
    rxplatform-blacklists = {
      uniform_bucket_level_access = false
    },
    rxplatform-list-uploads = {
      uniform_bucket_level_access = false
    },
    rxplatform-import-audience = {
      uniform_bucket_level_access = false
    },
    rxplatform-export-audience = {
      uniform_bucket_level_access = false
    }
  }
  public_buckets_set_policy = {
    rxplatform-creative-assets = {
      name = "${var.environment}-rxplatform-creative-assets"
    }
  }
}

resource "google_storage_bucket" "buckets" {
  for_each                    = local.buckets
  name                        = "${var.environment}-${each.key}"
  force_destroy               = true
  uniform_bucket_level_access = each.value["uniform_bucket_level_access"]

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

/* 
data "google_iam_policy" "allviewer" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "allUsers",
    ]
  }
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket                      = local.public_buckets_set_policy.rxplatform-creative-assets.name
  policy_data                 = data.google_iam_policy.allviewer.policy_data
} 
*/
