variable "slack_webhook_url" {
  type        = string
  description = "The webhook URL for Slack notifications."
  sensitive   = true
}

variable "datadog_api_key" {
  type        = string
  description = "The Datadog API key."
  sensitive   = true
}
