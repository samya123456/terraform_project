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
