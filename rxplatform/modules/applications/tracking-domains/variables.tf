variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "namespace" {
  type        = string
  description = "The namespace for the app."
}

variable "service" {
  type = object({
    service_name : string
    service_port : string
  })
  description = "Details for the tracking domains service."
}

variable "tracking_domains" {
  type        = list(string)
  description = "List of the tracking domains."
}
