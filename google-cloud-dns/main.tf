locals {
  project_records = toset(split(",", file("${path.module}/domains/${var.domains_filename}")))
}

module "records" {
  source           = "./records/"
  project_id       = var.project_id
  domains_filename = var.domains_filename
  domainsilos_list = var.domainsilos_list
  project_records  = split(",", file("${path.module}/domains/${var.domains_filename}"))
}
