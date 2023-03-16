terraform {
  required_version = ">= 0.15.3"

  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
  }
}
