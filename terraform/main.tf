locals {
  project = "rxmg-infrastructure"
}

provider "google" {
  project = local.project
}

resource "google_storage_bucket" "terraform_state" {
  name                        = "${local.project}-terraform-state"
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 100
    }
  }
}
