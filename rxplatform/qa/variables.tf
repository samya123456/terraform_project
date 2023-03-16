variable "database_secrets" {
  type        = map(map(string))
  description = "Secrets for the databases."
  sensitive   = true
}

variable "tracking_domains" {
  type        = list(string)
  description = "List of the tracking domains."
}

variable "rediscloud" {
  type = object({
    credentials = object({
      api_key : string
      secret_key : string
    })
  })
  description = "Secrets for the Redis provider."
  sensitive   = true
}

variable "mongodbatlas" {
  type = object({
    credentials = object({
      public_key : string
      private_key : string
    })
  })
  description = "Secrets for the MongoDB Atlas provider."
  sensitive   = true
}
