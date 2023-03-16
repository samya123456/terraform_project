output "service_account_name" {
  value       = local.kubernetes_service_account_name
  description = "The kubernetes service account name for the app's deployment."
}
