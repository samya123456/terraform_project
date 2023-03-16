output "cluster_host" {
  value       = module.cluster.cluster_host
  description = "The development cluster endpoint."
}

output "cluster_cert" {
  value       = module.cluster.cluster_cert
  description = "The development cluster CA certificate."
}

output "cluster_subnetwork" {
  value       = module.cluster.subnetwork
  description = "The development cluster subnetwork."
}

output "openvpncloud_network_id" {
  value       = data.openvpncloud_network.network.network_id
  description = "The OpenVPN Cloud Network ID for all development environments."
}
