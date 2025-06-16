variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_credentials_file" {
  description = "Path to the GCP service account JSON credentials"
  type        = string
}

variable "gcp_network_self_link" {
  description = "Self link of the VPC network"
  type        = string
}
variable "redis_droplet_size" {
  description = "Droplet size for redis"
  type        = string
  default     = ""
}

variable "redis_droplet_image" {
  description = "Image for redis Droplet"
  type        = string
  default     = ""
}

variable "redis_region" {
  description = "Region for redis Droplet"
  type        = string
}

variable "redis_password" {
  description = "Password to secure redis"
  type        = string
}

variable "private_key_path" {
  description = "Path to your SSH private key"
  type        = string
}


provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}


resource "google_compute_instance" "redis" {
  name         = "redis"
  machine_type = var.redis_droplet_size
  zone         = var.redis_region

  boot_disk {
    initialize_params {
      image = var.redis_droplet_image
    }
  }

  metadata = {
    ssh-keys = "root:${file(var.private_key_path)}"
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
  inline = [
    "bash -c 'set -eux && while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo \"Waiting for apt lock...\"; sleep 3; done && apt-get update -y || true && apt-get install -y redis-server && sed -i \"s/^#\\?\\s*bind .*/bind 0.0.0.0/\" /etc/redis/redis.conf && sed -i \"s/^#\\?\\s*protected-mode .*/protected-mode no/\" /etc/redis/redis.conf && sed -i \"s/^#\\?\\s*requirepass .*/requirepass ${var.redis_password}/\" /etc/redis/redis.conf && systemctl enable redis-server && systemctl restart redis-server'"
    ]
  }
}

#@tofuhub:is_used_by->redis_resource
resource "google_compute_firewall" "redis_fw" {
  name    = "redis-firewall"
  network = var.gcp_network_self_link

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}

# Assigns the mosquitto droplet to the project

output "redis_host" {
  value = google_compute_instance.redis.network_interface[0].access_config[0].nat_ip
}

output "redis_port" {
  value = "6379"
}

output "redis_password" {
  value = var.redis_password
  sensitive = true
}

