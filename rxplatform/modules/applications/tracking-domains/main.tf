locals {
  labels = {
    environment = var.environment
  }
  cert_manager_namespace  = "cert-manager"
  app                     = "tracking-domains"
  email                   = "rxplatform-${var.environment}@rxmg.com"
  certificate_issuer_name = "${var.environment}-${local.app}-certificate-issuer"
  certificate_issuer_type = "Issuer"
  tracking_domains        = toset(var.tracking_domains)
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    labels = {
      environment = var.environment
      app         = local.app
    }
    name = local.cert_manager_namespace
  }
}

resource "helm_release" "cert_manager" {
  name        = "cert-manager"
  description = "Helm chart release for running Let's Encrypt certificate manager on Kubernetes."
  repository  = "https://charts.jetstack.io"
  chart       = "cert-manager"
  namespace   = kubernetes_namespace.namespace.metadata[0].name
  wait        = true

  set {
    name  = "installCRDs"
    value = "true"
    type  = "string"
  }

  set {
    name  = "extraArgs"
    value = "{--enable-certificate-owner-ref=true}"
    type  = "string"
  }
}

resource "google_compute_global_address" "static_ip" {
  name        = "${var.environment}-${local.app}-ingress-ip"
  description = "Static IP for ${var.environment} cluster ${replace(local.app, "-", " ")} ingress."
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    namespace = var.namespace
    name      = "${var.environment}-${local.app}-ingress"
    labels    = local.labels
    annotations = {
      "kubernetes.io/ingress.class" : "gce",
      # "kubernetes.io/ingress.allow-http" : "false", # If there is no tracking domain, no SSL certs are available for this to work
      "kubernetes.io/ingress.global-static-ip-name" : google_compute_global_address.static_ip.name
      "cert-manager.io/issue-temporary-certificate" : "true"
      "acme.cert-manager.io/http01-edit-in-place" : "true"
      "cert-manager.io/issuer" : local.certificate_issuer_name
    }
  }

  spec {
    dynamic "rule" {
      for_each = local.tracking_domains
      content {
        host = rule.key
        http {
          path {
            path = "/*"
            backend {
              service_name = var.service.service_name
              service_port = var.service.service_port
            }
          }
        }
      }
    }
    dynamic "tls" {
      for_each = local.tracking_domains
      content {
        hosts       = [tls.value]
        secret_name = "${var.environment}-${replace(tls.value, ".", "-")}-secret"
      }
    }
  }
}

resource "kubernetes_manifest" "certificates" {
  depends_on = [
    helm_release.cert_manager
  ]
  for_each = local.tracking_domains
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.environment}-${replace(each.key, ".", "-")}-certificate"
      "namespace" = var.namespace
    }
    "spec" = {
      "secretName" : "${var.environment}-${replace(each.key, ".", "-")}-secret"
      "duration" : "2160h0m0s"   # 90d
      "renewBefore" : "360h0m0s" # 15d
      "subject" = {
        "organizations" = [each.key]
      }
      "privateKey" = {
        "algorithm" : "RSA"
        "encoding" : "PKCS1"
        "size" : "2048"
        "rotationPolicy" : "Always"
      }
      "usages" = [
        "server auth",
        "client auth"
      ]
      "dnsNames" = [
        each.key
      ]
      "issuerRef" = {
        "name" : local.certificate_issuer_name
        "kind" : local.certificate_issuer_type
      }
    }
  }
}

resource "kubernetes_manifest" "cert_manager_issuer" {
  depends_on = [
    helm_release.cert_manager
  ]
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = local.certificate_issuer_type
    "metadata" = {
      "name"      = local.certificate_issuer_name
      "namespace" = var.namespace
    }
    "spec" = {
      "acme" = {
        "email" : local.email
        "server" : "https://acme-v02.api.letsencrypt.org/directory"
        # "server" : "https://acme-staging-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" : "${var.environment}-${local.app}-certificate-issuer-account-secret"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "name" : kubernetes_ingress.ingress.metadata[0].name
              }
            }
          }
        ]
      }
    }
  }
}
