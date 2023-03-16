variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "cluster_name" {
  type        = string
  description = "The cluster name to install this resource in."
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API key."
  sensitive   = true
}
