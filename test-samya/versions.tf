terraform {
  required_version = ">= 0.15.3"
  required_providers {
    openvpn-cloud = {
      source  = "OpenVPN/openvpn-cloud"
      version = "0.0.9"
    }
  }
}
