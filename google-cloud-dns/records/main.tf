locals {
  project_records = toset(var.project_records)
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

resource "google_dns_managed_zone" "hosted_zones" {
  for_each    = local.project_records
  name        = "${replace(each.key, ".", "-")}-dns-zone"
  dns_name    = "${each.key}."
  description = "Hosted DNS zone for ${each.key}"
}

resource "google_compute_firewall" "ssh_rule" {
  name    = "ssh-fw-rules"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [
    "73.220.151.56/32"
  ]
  source_tags = ["ssh"]
}

# START MAIL SERVER CONFIGURATION
resource "google_compute_address" "mail_ip" {
  name     = "mail-server-ip"
  region   = "us-central1"
}

# CREATE MAIL FIREWALL RULES
data "google_compute_network" "default" {
  name                    = "default"
}

resource "google_compute_firewall" "compliance_mail_rules" {
  name    = "compliance-mail-fw-rules"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["25", "2525", "465", "587"]
  }

  source_tags = ["compliance"]
}

// Create Company Mail VM.
resource "google_compute_instance" "compliance_mail" {

  name         = "compliance-mail"
  description  = "Instance for Company/Silo Administrative Mail"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  hostname     = "compliance-mail.localhost"

  tags = ["compliance", "ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"
      access_config {
        nat_ip = google_compute_address.mail_ip.address
      }
  }
  metadata_startup_script = templatefile("${path.module}/compliance_startup.sh", { main_conf = file("${path.module}/main.cf") })
}

resource "google_dns_record_set" "a_mail_dns_record" {
  for_each     = local.project_records
  managed_zone = google_dns_managed_zone.hosted_zones[each.key].name
  name         = "mail.${each.key}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.mail_ip.address]
}

resource "google_dns_record_set" "mx_dns_record" {
  for_each     = local.project_records
  managed_zone = google_dns_managed_zone.hosted_zones[each.key].name
  name         = "${each.key}."
  type         = "MX"
  ttl          = 300

  rrdatas = ["10 mail.${each.key}."]
}

resource "google_dns_record_set" "txt_mail_dns_record" {
  for_each     = local.project_records
  managed_zone = google_dns_managed_zone.hosted_zones[each.key].name
  name         = "${each.key}."
  type         = "TXT"
  ttl          = 300

  rrdatas = ["v=spf1 mx ~all"]
}
# END MAIL SERVER CONFIGURATION


# START WEB SERVER CONFIGURATION
resource "google_compute_address" "web_ip" {
  name     = "web-server-ip"
  region   = "us-central1"
}

# CREATE WEB FIREWALL RULES

resource "google_compute_firewall" "haproxy-web-rules" {
  name    = "haproxy-web-fw-rules"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_tags = ["web"]
}

// Create Haproxy-web VM.
resource "google_compute_instance" "web-forwarding" {

  name         = "web-forwarding"
  description  = "Instance for Domain Silo web infrastructure"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  hostname     = "web-forwarding.localhost"

  tags = ["http-server", "https-server", "ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"
      access_config {
        nat_ip = google_compute_address.web_ip.address
      }
  }
  metadata_startup_script = templatefile("${path.module}/web_startup.sh", { haproxy_conf = file("${path.module}/haproxy.cfg") })
}

resource "google_dns_record_set" "a_web_dns_record" {
  for_each     = local.project_records
  managed_zone = google_dns_managed_zone.hosted_zones[each.key].name
  name         = "${each.key}."
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_address.web_ip.address]
}

resource "google_dns_record_set" "cname_dns_record" {
  for_each     = local.project_records
  managed_zone = google_dns_managed_zone.hosted_zones[each.key].name
  name         = "www.${each.key}."
  type         = "CNAME"
  ttl          = 300

  rrdatas = ["${each.key}."]
}
# END WEB SERVER CONFIGURATION
