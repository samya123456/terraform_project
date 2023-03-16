locals {
  project     = "rxmg-infrastructure"
  region      = "us-central1"
  environment = "development"

  service_account_key_admin_role = "roles/iam.serviceAccountKeyAdmin"

  senior_permissions = ["roles/logging.privateLogViewer", "roles/container.clusterViewer", "roles/container.developer"]

  senior_developers = [
    for developer in var.developers : developer.email
    if lookup(developer, "senior", false)
  ]
}

terraform {
  backend "gcs" {
    bucket = "rxmg-infrastructure-terraform-state"
    prefix = "development"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

provider "google-beta" {
  project = local.project
  region  = local.region
}

module "buckets" {
  source      = "../rxplatform/modules/buckets"
  environment = local.environment
}

resource "google_project_iam_custom_role" "developer_role" {
  role_id     = "Developer"
  title       = "Developer"
  description = "Role given to developers to work on the RXPlatform."
  stage       = "GA"
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update"
  ]
}

resource "google_service_account" "developer_service_accounts" {
  for_each     = var.developers
  account_id   = each.key
  display_name = "${each.value["name"]} Service Account"
  description  = "Service account for ${each.value["name"]}."
}

resource "google_project_iam_binding" "developer_service_account_bindings" {
  role = google_project_iam_custom_role.developer_role.id

  members = [for developer_service_account in google_service_account.developer_service_accounts : "serviceAccount:${developer_service_account.email}"]
  condition {
    title       = "Allow Access To Development Buckets"
    description = "Condition only allows access to the ${local.environment} buckets."
    expression  = "(resource.type == \"storage.googleapis.com/Bucket\" || resource.type == \"storage.googleapis.com/Object\") && resource.name.startsWith(\"projects/_/buckets/${local.environment}-\")"
  }
}

resource "google_project_iam_member" "developer_permission" {
  for_each = var.developers
  role     = local.service_account_key_admin_role
  member   = "user:${each.value["email"]}"
  condition {
    title       = "Allow Developer Service Account Access"
    description = "Condition only allows access to the service account for ${each.value["name"]}."
    expression  = "resource.name == \"projects/-/serviceAccounts/${google_service_account.developer_service_accounts[each.key].unique_id}\""
  }
}

resource "google_project_iam_member" "senior_permission" {
  for_each = { for item in setproduct(local.senior_developers, local.senior_permissions) : "${item[0]}_${item[1]}" => { email : item[1], role : item[0] } }
  role     = each.value.email
  member   = "user:${each.value.role}"
}

module "coder" {
  source      = "./coder"
  environment = local.environment
}
