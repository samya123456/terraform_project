variable "domains_filename" {
  type        = string
  description = "Filename for the domains."
}

variable "project_id" {
  type        = string
  description = "The project ID."
}

variable "domainsilos_list" {
  type        = list(string)
  description = "List of all domain silos."
}
