variable "environment" {
  type        = string
  description = "The environment for the applications."
}

variable "namespace" {
  type        = string
  description = "The namespace for the applications."
}

variable "project_id" {
  type        = string
  description = "The project ID that's being worked in. Should be the same as the project in the Google provider block."
}

variable "databases" {
  type = object({
    mongodb = object({
      dsn           = string
      database_name = string
    })
    sql = object({
      host                    = string
      port                    = number
      database_name           = string
      datastore_database_name = string
      user                    = string
      password                = string
    })
    redis = object({
      host     = string
      port     = number
      password = string
    })
    influxdb = object({
      host          = string
      port          = number
      database_name = string
      user          = string
      password      = string
      ssl           = string
    })
    elasticsearch = object({
      host     = string
      port     = number
      scheme   = string
      user     = string
      password = string
    })
  })
  description = "The details for the databases used by the applications."
}

variable "google_secret_environment" {
  type        = string
  description = "The environment for the secret in Google Secret Manager."
}

variable "image_environments" {
  type = object({
    backend  = string
    frontend = string
    intake   = string
  })
  description = "The image environments for the applications."
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork for the applications."
}

variable "openvpncloud_network_id" {
  type        = string
  description = "The OpenVPN Cloud Network ID for the applications."
}
