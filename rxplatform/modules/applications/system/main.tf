locals {
  system_namespace                    = "kube-system"
  kube_dns_pod_disruption_budget_name = "kube-dns-pdb"
  kube_dns_labels = {
    k8s-app = "kube-dns"
  }
}

resource "kubernetes_pod_disruption_budget" "kube_dns" {
  metadata {
    namespace = local.system_namespace
    name      = local.kube_dns_pod_disruption_budget_name
    labels    = local.kube_dns_labels
  }

  spec {
    max_unavailable = 1
    selector {
      match_labels = local.kube_dns_labels
    }
  }
}
