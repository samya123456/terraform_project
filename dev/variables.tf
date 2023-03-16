variable "developers" {
  type = map(any)
  #   type = map(object({
  #     email  = string
  #     name   = string
  #     senior = optional(bool)
  #   }))
  description = "Map of developers."
}
