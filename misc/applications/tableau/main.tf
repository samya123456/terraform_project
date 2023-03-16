locals {
  app          = "tableau"
  tableau_host = "tableau.rxmg.app"
}

resource "google_compute_network" "private_network" {
  name                    = "tableau"
  description             = "VPC network for ${local.app}."
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main_subnetwork" {
  name          = local.app
  description   = "Subnet for ${local.app}."
  ip_cidr_range = "10.128.0.0/20"
  network       = google_compute_network.private_network.id
}

resource "google_compute_subnetwork" "proxy_only_subnetwork" {
  provider      = google-beta
  name          = "${local.app}-internal-load-balancing"
  description   = "Subnet for ${local.app} internal load balancing."
  ip_cidr_range = "10.126.0.0/20"
  network       = google_compute_network.private_network.id
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
}

resource "google_compute_instance" "tableau_server" {
  name                = "tableau-rxp-01"
  zone                = "us-central1-a"
  machine_type        = "e2-standard-16"
  hostname            = local.tableau_host
  deletion_protection = true
  tags = [
    "http-server",
    "https-server",
    "tableau-rxp",
  ]

  network_interface {
    network    = google_compute_network.private_network.id
    subnetwork = google_compute_subnetwork.main_subnetwork.id
    access_config {
    }
  }
  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/beta/projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20220331a"
    }
  }

  service_account {
    email = "362975759951-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}

resource "google_compute_address" "tableau_reserved_ip" {
  provider     = google-beta
  name         = "${local.app}-internal-load-balancer-ip"
  subnetwork   = google_compute_subnetwork.main_subnetwork.id
  address_type = "INTERNAL"
  purpose      = "SHARED_LOADBALANCER_VIP"
}

resource "google_compute_forwarding_rule" "tableau_load_balancer" {
  depends_on            = [google_compute_subnetwork.proxy_only_subnetwork]
  name                  = "${local.app}-internal-forwarding-rule"
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.tableau_reserved_ip.id
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.tableau_load_balancer.id
  network               = google_compute_network.private_network.id
  subnetwork            = google_compute_subnetwork.main_subnetwork.id
  network_tier          = "PREMIUM"
}

## BEGIN HTTPS

resource "google_compute_region_target_https_proxy" "tableau_load_balancer" {
  name             = "${local.app}-regional-target-https-proxy"
  url_map          = google_compute_region_url_map.tableau_load_balancer.id
  ssl_certificates = [google_compute_region_ssl_certificate.tableau_load_balancer.self_link]
}

resource "google_compute_region_url_map" "tableau_load_balancer" {
  name            = "${local.app}-regional-url-map"
  default_service = google_compute_region_backend_service.tableau_load_balancer.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_uuid" "private_certificate_uuid" {
}

resource "google_privateca_certificate" "private_certificate" {
  pool                  = "rxmg-com"
  certificate_authority = "20211118-hpc-kv9"
  location              = "us-central1"
  lifetime              = "63072000s"
  name                  = substr("${replace(local.tableau_host, ".", "-")}-${random_uuid.private_certificate_uuid.result}", 0, 63) # Max length is 63 characters
  config {
    subject_config {
      subject {
        common_name         = local.tableau_host
        country_code        = "US"
        organization        = "RX Marketing Group"
        organizational_unit = "Tech"
        locality            = "Irvine"
        province            = "California"
      }
      subject_alt_name {
        dns_names       = [local.tableau_host]
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
      key    = base64encode(tls_private_key.private_key.public_key_pem)
    }
  }
}

resource "google_compute_region_ssl_certificate" "tableau_load_balancer" {
  name        = substr("${replace(local.tableau_host, ".", "-")}-internal-certificate", 0, 61)
  description = "SSL cert for internal ${local.tableau_host}"
  private_key = tls_private_key.private_key.private_key_pem
  certificate = google_privateca_certificate.private_certificate.pem_certificate
}

## END HTTPS

## BEGIN HTTP REDIRECT

resource "google_compute_forwarding_rule" "tableau_load_balancer_http_redirect" {
  name                  = "${local.app}-http-redirect"
  ip_protocol           = "TCP"
  ip_address            = google_compute_address.tableau_reserved_ip.id # Same as HTTPS load balancer
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.tableau_load_balancer.id
  network               = google_compute_network.private_network.id
  subnetwork            = google_compute_subnetwork.main_subnetwork.id
  network_tier          = "PREMIUM"
}

resource "google_compute_region_target_http_proxy" "tableau_load_balancer" {
  name    = "${local.app}-target-http-proxy"
  url_map = google_compute_region_url_map.tableau_load_balancer_http_redirect.id
}

resource "google_compute_region_url_map" "tableau_load_balancer_http_redirect" {
  name            = "${local.app}-http-redirect-url-map"
  default_service = google_compute_region_backend_service.tableau_load_balancer.id
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.tableau_load_balancer.id
    path_rule {
      paths = ["/"]
      url_redirect {
        https_redirect         = true
        host_redirect          = "${google_compute_address.tableau_reserved_ip.address}:443"
        redirect_response_code = "PERMANENT_REDIRECT"
        strip_query            = true
      }
    }
  }
}

## END HTTP REDIRECT

## BEGIN BACKEND CONFIGURATION

resource "google_compute_region_backend_service" "tableau_load_balancer" {
  name     = "${local.app}-regional-backend-service"
  protocol = "HTTPS"
  #   port_name = "http-server"
  load_balancing_scheme = "INTERNAL_MANAGED"
  #   load_balancing_scheme = "INTERNAL"
  timeout_sec   = 10
  health_checks = [google_compute_region_health_check.tableau_load_balancer.id]
  backend {
    group           = google_compute_instance_group.tableau_servers.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_region_health_check" "tableau_load_balancer" {
  name = "${local.app}-regional-health-check"
  #   http_health_check {
  #     port_specification = "USE_FIXED_PORT"
  #     port               = 80
  #   }
  https_health_check {
    port = "443"
  }
}

resource "google_compute_instance_group" "tableau_servers" {
  name        = "${local.app}-servers"
  description = "Instance group for ${local.app}."

  instances = [
    google_compute_instance.tableau_server.id
  ]

  named_port {
    name = "http"
    port = "443"
  }

  zone = "us-central1-a"
}
## END BACKEND CONFIGURATION

## BEGIN FIREWALL RULES

resource "google_compute_firewall" "tableau_allow_health_check" {
  provider      = google-beta
  name          = "${local.app}-firewall-allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.private_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "35.235.240.0/20"]
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "tableau_allow_http_from_proxy" {
  provider      = google-beta
  name          = "${local.app}-allow-http-from-proxy"
  direction     = "INGRESS"
  network       = google_compute_network.private_network.id
  source_ranges = [google_compute_subnetwork.proxy_only_subnetwork.ip_cidr_range]
  target_tags   = ["http-server"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
}

## END FIREWALL RULES
