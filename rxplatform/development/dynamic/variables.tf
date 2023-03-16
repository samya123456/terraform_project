variable "backend_branch" {
  type        = string
  description = "The branch for the backend app."
  default     = "develop"
}

variable "frontend_branch" {
  type        = string
  description = "The branch for the frontend app."
  default     = "develop"
}

variable "intake_branch" {
  type        = string
  description = "The branch for the intake app."
  default     = "develop"
}

variable "openvpncloud" {
  type = object({
    base_url = string
    credentials = object({
      client_id : string
      client_secret : string
    })
  })
  description = "The configuration for OpenVPN Cloud."
  sensitive   = true
}
