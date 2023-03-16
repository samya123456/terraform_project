variable "environment" {
  type        = string
  description = "The environment for the resource."
}

variable "location" {
  type        = string
  description = "The location for the cluster. Specifying a zone will make a zonal cluster, while specifying a region will create a regional cluster."
}

variable "image_type" {
  type        = string
  description = "The image type for nodes in this cluster."
  default     = "COS_CONTAINERD"
}

variable "machine_type" {
  type        = string
  description = "The machine type for nodes in this cluster."
  default     = "e2-standard-8"
}

variable "min_nodes" {
  type        = number
  description = "The minimum number of nodes for this cluster."
}

variable "max_nodes" {
  type        = number
  description = "The maximum number of nodes for this cluster."
}

variable "private_configuration" {
  type = object({
    vpc_display_name = string
  })
  description = "The configuration values for the private cluster. Leave out if public cluster is desired."
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "The labels for the cluster and all associated nodes."
  default     = {}
}

variable "shielded_instance_config" {
  type = object({
    enable_integrity_monitoring = bool
    enable_secure_boot          = bool
  })
  description = "Configuration for shielded nodes."
  default = {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
  }
}
