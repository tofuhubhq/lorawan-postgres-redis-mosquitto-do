variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
}

variable "gcp_credentials" {
  description = "Path to service account json"
  type        = string
  default     = ""
}

variable "redis_instance_name" {
  type        = string
  description = "Name of redis VM"
}

variable "machine_type" {
  type        = string
  description = "GCE machine type"
}

variable "redis_password" {
  type        = string
  description = "Password to secure redis"
}

provider "google" {
  project     = var.gcp_project
  zone        = var.gcp_zone
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

resource "google_compute_instance" "redis" {
  name         = var.redis_instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["redis", "ssh"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y redis-server
    sed -i "s/^#\\?requirepass .*/requirepass ${var.redis_password}/" /etc/redis/redis.conf
    sed -i "s/^bind .*/bind 0.0.0.0/" /etc/redis/redis.conf
    systemctl enable redis-server
    systemctl restart redis-server
  EOT
}

output "redis_host" {
  value = google_compute_instance.redis.network_interface[0].access_config[0].nat_ip
}

output "redis_password" {
  value     = var.redis_password
  sensitive = true
}
