terraform {
  required_version = ">= 0.15.3"

  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "0.2.4"
    }
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
}
