provider "openvpn-cloud" {
  base_url      = "https://samyanandy.api.openvpn.com"
  client_id     = "8VwLIcQvkYWENXMGDu8O1j4sivhrTJkB.samyanandy"
  client_secret = "pGutPTHhOfplgOSfvghZFfjNSRQADSBLL7IfsZW1tonLQUD3u5l2eMR5UUyVAWXf"
}


resource "openvpncloud_network" "network" {
  provider = openvpn-cloud
  name     = "dummy_network"
  default_connector {
    name          = "dummy_connector"
    vpn_region_id = "ap-south-1"

  }

  default_route {
    value = "samya.com"
    type  = "DOMAIN"

  }
}

resource "openvpncloud_route" "backend" {
  provider        = openvpn-cloud
  network_item_id = openvpncloud_network.network.id
  #description = "RXPlatform ${var.environment} backend URL."
  type        = "DOMAIN"
  description = "yigit.com"
  value       = "yigit.com"
}


# resource "openvpncloud_route" "backend_1" {
#   provider   = openvpncloud
#   network_id = "afa84bbf-95d2-4d68-9ff3-da246aa49d78"
#   #description = "RXPlatform ${var.environment} backend URL."
#   type        = "DOMAIN"
#   description = "google.com"
#   value       = "google.com"
# }
# data "openvpncloud_network_routes" "network" {
#   provider        = openvpn-cloud
#   network_item_id = "afa84bbf-95d2-4d68-9ff3-da246aa49d78"

# }
