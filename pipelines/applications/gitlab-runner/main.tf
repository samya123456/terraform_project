locals {
  app                     = "gitlab-runner"
  max_concurrent_jobs     = 30
  check_for_jobs_interval = 5
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = var.environment
      name        = var.namespace
    }
    name = var.namespace
  }
}

resource "google_project_iam_custom_role" "certificate_admin" {
  role_id     = "CAServiceCertificateAdmin"
  title       = "CA Service Certificate Admin"
  description = "Create and revoke certificates."
  stage       = "GA"
  permissions = [
    "privateca.caPools.get",
    "privateca.caPools.list",
    "privateca.certificateAuthorities.get",
    "privateca.certificateAuthorities.list",
    "privateca.certificates.create",
    "privateca.certificates.get",
    "privateca.certificates.list",
    "privateca.certificates.update",
  ]
}

resource "google_project_iam_custom_role" "dns_record_sets_admin" {
  role_id     = "DNSRecordSetsAdmin"
  title       = "DNS Record Sets Admin"
  description = "Create, delete, update, get, list DNS record sets."
  stage       = "GA"
  permissions = [
    "dns.changes.create",
    "dns.changes.get",
    "dns.changes.list",
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list"
  ]
}

module "service_account" {
  source      = "../../../modules/service_account"
  environment = var.environment
  namespace   = var.namespace
  app         = local.app
  project_id  = var.project_id
  roles = [
    { role : "cloudbuild.builds.editor", conditions : [] },
    { role : "cloudsql.client", conditions : [] },
    { role : "container.admin", conditions : [] },
    { role : "logging.admin", conditions : [] },
    { role : "secretmanager.secretAccessor", conditions : [] },
    { role : "secretmanager.viewer", conditions : [] },
    { role : "storage.admin", conditions : [] },
    { role : "iam.serviceAccountAdmin", conditions : [] },
    { role : "resourcemanager.projectIamAdmin", conditions : [] },
    { role : "compute.loadBalancerAdmin", conditions : [] },
    { role : "compute.networkAdmin", conditions : [] }
  ]
  custom_roles = [
    { role : google_project_iam_custom_role.certificate_admin.id, conditions : [] },
    { role : google_project_iam_custom_role.dns_record_sets_admin.id, conditions : [] }
  ]
  service_account_limited_roles = [
    { role : "iam.serviceAccountTokenCreator", conditions : [] }
  ]
}

resource "helm_release" "gitlab_runner" {
  name        = "gitlab-runner"
  description = "Helm chart release for running GitLab runners on Kubernetes."
  repository  = "https://charts.gitlab.io"
  chart       = "gitlab-runner"

  namespace = var.namespace

  set {
    name  = "gitlabUrl"
    value = "https://gitlab.com/"
    type  = "string"
  }

  set_sensitive {
    name  = "runnerRegistrationToken"
    value = var.gitlab_runner_token
    type  = "string"
  }

  set {
    name  = "concurrent"
    value = local.max_concurrent_jobs
    type  = "string"
  }

  set {
    name  = "checkInterval"
    value = local.check_for_jobs_interval
    type  = "string"
  }

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "runners.serviceAccountName"
    value = module.service_account.service_account_name
    type  = "string"
  }
}
