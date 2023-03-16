locals {
  database      = "mongodb"
  database_port = "27017"
  instances     = toset(["0", "1", "2"])
  labels = {
    environment = var.environment
    app         = local.database
  }
  machine_type        = "n2d-highmem-4"
  storage_size        = 750
  storage_type        = "pd-ssd"
  storage_device_name = local.database
  zones               = formatlist("${var.region}-%s", ["a", "b"])
  dns_zone            = "rxmg-app"
  dns_name            = "rxmg.app"
  network_tags        = ["${var.environment}-${local.database}"]
  network             = "rxplatform-${var.environment}"
}

// TODO: Add SSL to client-server communication.
// TODO: Change keyfile to use x.509 for internal authentication.
// TODO: Automate the replica setup on the primary node.
// TODO: Look into moving this to Kubernetes, to see if that is more performant or simpler.
// TODO: Look into using xfs for file mount.

// Create disks for database,
resource "google_compute_region_disk" "mongodb_persistent_storage" {
  for_each      = local.instances
  name          = "${var.environment}-${local.database}-${each.key}"
  description   = "Persistent regional storage for ${var.environment} MongoDB instance ${each.key}."
  size          = local.storage_size
  type          = local.storage_type
  labels        = local.labels
  replica_zones = local.zones
}

// Create snapshot backup schedule.
resource "google_compute_resource_policy" "snapshot_backup_schedule" {
  name        = "${var.environment}-${local.database}-backup-schedule"
  description = "Snapshot backup schedule for ${var.environment} MongoDB disks."
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "01:00"
      }
    }

    retention_policy {
      max_retention_days = 14
    }

    snapshot_properties {
      labels      = local.labels
      guest_flush = false
    }
  }
}

resource "google_compute_region_disk_resource_policy_attachment" "mongodb_snapshot_backup" {
  for_each = google_compute_region_disk.mongodb_persistent_storage
  name     = google_compute_resource_policy.snapshot_backup_schedule.name
  disk     = each.value.name
  region   = var.region
}

// Password used for replica set internal authentication.
resource "random_password" "replica_set_shared_password" {
  length  = 40
  special = false
}

// Create database VMs.
resource "google_compute_instance" "mongodb_instance" {
  for_each     = google_compute_region_disk.mongodb_persistent_storage
  name         = each.value.name
  description  = "MongoDB instance ${each.key} for ${var.environment}."
  machine_type = local.machine_type
  zone         = each.key != "2" ? "${var.region}-a" : "${var.region}-b"
  hostname     = "${each.value.name}.${local.dns_name}"

  tags   = local.network_tags
  labels = local.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = local.network
  }

  attached_disk {
    source      = each.value.id
    device_name = local.storage_device_name
  }

  metadata_startup_script = templatefile("${path.module}/mongodb_startup.sh", { replica_set_shared_password = random_password.replica_set_shared_password.result, mongod_conf = file("${path.module}/mongod.conf") })

  lifecycle {
    ignore_changes = [metadata] // May have added SSH keys
  }
}

resource "google_compute_firewall" "allow_mongodb" {
  name    = "rxplatform-${var.environment}-allow-${local.database}"
  network = local.network

  allow {
    protocol = "tcp"
    ports    = [local.database_port]
  }

  target_tags = local.network_tags
}

// After this, for first time setup of the DISKS, not the Compute Instances, the following commands must be run on one of the instances.
/*
mongosh

// Inside mongo shell.
rs.initiate()
rs.status()

// Passwords are found in LastPass
use admin
db.createUser(
  {
    user: "admin",
    pwd: "${var.admin_password}",
    roles: [
      {
        role: "readWriteAnyDatabase",
        db: "admin"
      },
      {
        role: "userAdminAnyDatabase",
        db: "admin"
      },
      {
        role: "dbAdminAnyDatabase",
        db: "admin"
      },
      {
        role: "clusterAdmin",
        db: "admin"
      }
    ]
  }
)
exit
// Outside of mongo shell.
mongosh -u admin
// This is prompt for the last command, use the password set up previously.
${var.admin_password}

// Inside mongo shell
use audiences
db.createUser(
  {
    user: "rxplatform",
    pwd: "${var.rxplatform_password}",
    roles: [
      {
        role: "readWrite",
        db: "audiences"
      }
    ]
  }
)
rs.conf()
cfg = rs.conf()
cfg.members[0].priority = 10
cfg.members[0].host = "${var.current_internal_ip_address}:27017"
rs.reconfig(cfg)
// These are examples, do this for all the instances.
rs.add( { host: "${var.member_internal_ip_address}:27017", priority: 5, votes: 1 } )
rs.add( { host: "${var.member_internal_ip_address}:27017", priority: 5, votes: 1 } )
// Verify that the current instance is PRIMARY and the other instances are SECONDARY
rs.status()
*/

// After this, make sure that the DSN for the RXPlatform apps is updated with the DNS names and set up for SSL.
// Ex. mongodb://rxplatform:password@${var.environment}-mongodb-0.rxmg.app:443,${var.environment}-mongodb-1.rxmg.app:443,${var.environment}-mongodb-2.rxmg.app:443/audiences?replicaSet=mongodb-repl-set&ssl=true
