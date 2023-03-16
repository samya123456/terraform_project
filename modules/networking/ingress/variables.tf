variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "namespace" {
  type        = string
  description = "The namespace for the ingress."
}

variable "networking" {
  type = map(
    object({
      zone         = string
      service_name = string
      service_port = string
      paths        = list(string)
    })
  )
  description = "The map of networking details for the ingress."
}

variable "internal_configuration" {
  type = object({
    subnetwork = string
  })
  description = "The configuration values for the internal ingress. Leave out if public ingress is desired."
  default     = null
}


variable "extra_rules" {
  type = map(map(object({
    service_name = string
    service_port = string
  })))
  description = "The map of extra rules for the ingress, if any."
  default     = {}
}

variable "extra_annotations" {
  type        = map(string)
  description = "The map of extra annotations for the ingress, if any."
  default     = {}
}

variable "tls" {
  type        = map(list(string))
  description = "The map of TLS secrets and their hosts, if any."
  default     = {}
}
