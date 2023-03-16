locals {
  namespace = "datadog"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = var.environment
    }
    name = local.namespace
  }
}

resource "helm_release" "datadog_agent" {
  name        = "datadog-agent"
  description = "Helm chart release for running the Datadog agent on Kubernetes."
  repository  = "https://helm.datadoghq.com"
  chart       = "datadog"

  namespace = kubernetes_namespace.namespace.metadata[0].name

  values = [
    templatefile("${path.module}/values.yaml", { cluster_name : var.cluster_name, environment : var.environment })
  ]

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
    type  = "string"
  }
}
