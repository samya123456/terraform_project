terraform {
  required_version = ">= 0.15.3"
  required_providers {
    # openvpncloud = {
    #   source  = "RXMG/openvpncloud"
    #   version = "0.0.2"
    # }
    openvpn-cloud = {
      source = "OpenVPN/openvpn-cloud"
      version = "0.0.6"
    }
  }
}
