locals {
  labels = {
    environment = var.environment
  }
  ingress_name_infix = var.internal_configuration != null ? "regional-" : ""
  ingress_name       = "${var.environment}-${local.ingress_name_infix}ingress"

  internal_static_ip_name_infix        = var.internal_configuration != null ? "regional-" : ""
  internal_static_ip_description_infix = var.internal_configuration != null ? "regional " : ""
  static_ip_name                       = "${var.environment}-${local.internal_static_ip_name_infix}ingress-ip"
  static_ip_description                = "Static IP for ${var.environment} cluster ${local.internal_static_ip_description_infix}ingress."

  domains = formatlist("%s.", keys(var.networking))
  ttl     = 300
}

## EXTERNAL DEPENDENCIES ##
resource "google_compute_global_address" "static_ip" {
  count       = var.internal_configuration != null ? 0 : 1
  name        = local.static_ip_name
  description = local.static_ip_description
}

resource "google_compute_managed_ssl_certificate" "google_ssl_certificates" {
  for_each    = var.internal_configuration != null ? {} : var.networking
  name        = substr("${var.environment}-${replace(each.key, ".", "-")}-global-certificate", 0, 61) # Max length is 61 characters
  description = "SSL certificate for ${each.key} used by ${var.environment} cluster ingress."

  managed {
    domains = [each.key]
  }
}

resource "google_dns_record_set" "domain_a_record" {
  for_each     = var.internal_configuration != null ? {} : var.networking
  managed_zone = each.value["zone"]
  name         = "${each.key}."
  type         = "A"
  rrdatas      = [google_compute_global_address.static_ip[0].address]
  ttl          = local.ttl
}
## END EXTERNAL DEPENDENCIES ##


## INTERNAL DEPENDENCIES ##
resource "google_compute_address" "static_ip" {
  count        = var.internal_configuration != null ? 1 : 0
  name         = local.static_ip_name
  description  = local.static_ip_description
  subnetwork   = var.internal_configuration.subnetwork
  purpose      = "GCE_ENDPOINT"
  address_type = "INTERNAL"
}

resource "tls_private_key" "private_keys" {
  for_each  = var.internal_configuration != null ? var.networking : {}
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_uuid" "private_certificate_uuids" {
  for_each = var.internal_configuration != null ? var.networking : {}
}

resource "google_privateca_certificate" "private_certificates" {
  for_each              = var.internal_configuration != null ? var.networking : {}
  pool                  = "rxmg-com"
  certificate_authority = "20211118-hpc-kv9"
  location              = "us-central1"
  lifetime              = "63072000s"
  name                  = substr("${var.environment}-${replace(each.key, ".", "-")}-${random_uuid.private_certificate_uuids[each.key].result}", 0, 63) # Max length is 63 characters
  config {
    subject_config {
      subject {
        common_name         = each.key
        country_code        = "US"
        organization        = "RX Marketing Group"
        organizational_unit = "Tech"
        locality            = "Irvine"
        province            = "California"
      }
      subject_alt_name {
        dns_names       = [each.key]
        email_addresses = []
        ip_addresses    = []
        uris            = []
      }
    }
    x509_config {
      aia_ocsp_servers = []
      ca_options {
        is_ca                  = false
        max_issuer_path_length = 0
      }
      key_usage {
        base_key_usage {
          cert_sign          = false
          content_commitment = false
          data_encipherment  = false
          decipher_only      = false
          encipher_only      = false
          key_agreement      = false
          crl_sign           = false
          digital_signature  = true
          key_encipherment   = true
        }
        extended_key_usage {
          client_auth      = false
          code_signing     = false
          email_protection = false
          ocsp_signing     = false
          time_stamping    = false
          server_auth      = true
        }
      }
    }
    public_key {
      format = "PEM"
      key    = base64encode(tls_private_key.private_keys[each.key].public_key_pem)
    }
  }
}

resource "google_compute_region_ssl_certificate" "google_ssl_certificates" {
  for_each    = google_privateca_certificate.private_certificates
  name        = substr("${var.environment}-${replace(each.key, ".", "-")}-internal-certificate", 0, 61)
  description = "SSL cert for internal ${var.environment} ${each.key}"
  private_key = tls_private_key.private_keys[each.key].private_key_pem
  certificate = google_privateca_certificate.private_certificates[each.key].pem_certificate
}
## END INTERNAL DEPENDENCIES ##

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    namespace = var.namespace
    name      = local.ingress_name
    labels    = local.labels
    annotations = merge({
      "kubernetes.io/ingress.allow-http" : "false",
      "kubernetes.io/ingress.class" : var.internal_configuration != null ? "gce-internal" : "gce",
      "ingress.gcp.kubernetes.io/pre-shared-cert" : var.internal_configuration != null ? join(",", [for cert in google_compute_region_ssl_certificate.google_ssl_certificates : cert.name]) : join(",", [for cert in google_compute_managed_ssl_certificate.google_ssl_certificates : cert.name])
      var.internal_configuration != null ? "kubernetes.io/ingress.regional-static-ip-name" : "kubernetes.io/ingress.global-static-ip-name" : var.internal_configuration != null ? google_compute_address.static_ip[0].name : google_compute_global_address.static_ip[0].name
    }, var.extra_annotations)
  }

  spec {
    dynamic "rule" {
      for_each = var.networking
      content {
        host = rule.key
        http {
          dynamic "path" {
            for_each = rule.value["paths"]
            content {
              path = path.value
              backend {
                service {
                    name = rule.value["service_name"]
                    port {
                        number = rule.value["service_port"]
                    }
                }
            }
          }
        }
      }
    }
  }
    dynamic "rule" {
      for_each = var.extra_rules
      content {
        host = rule.key
        http {
          dynamic "path" {
            for_each = rule.value
            content {
              path = path.key
              backend {
                service {
                    name = rule.value["service_name"]
                    port {
                        number = rule.value["service_port"]
                    }
                }
              }
            }
          }
        }
      }
    }
    dynamic "tls" {
      for_each = var.tls
      content {
        hosts       = tls.value
        secret_name = tls.key
      }
    }
  }
}
