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

variable "gcp_dns_zone" {
  description = "Name of the managed DNS zone"
  type        = string
}

variable "do_mosquitto_region" {
  description = "Digital ocean mosquitto region"
  type        = string
}

variable "do_mosquitto_image" {
  description = "Digital ocean mosquitto image"
  type        = string
}

variable "do_mosquitto_size" {
  description = "Digital ocean mosquitto size"
  type        = string
}

variable "do_mosquitto_username" {
  description = "Digital ocean mosquitto username"
  type        = string
}

variable "do_mosquitto_password" {
  description = "Digital ocean mosquitto password"
  type        = string
}

variable "do_domain" {
  description = "Digital ocean domain"
  type        = string
  default     = ""
}

variable "mosquitto_config_path" {
  description = "Path to the Mosquitto config file"
  type        = string
}

variable "private_key_path" {
  description = "Path to your private SSH key"
  type        = string
}


# Provider
provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}

resource "google_compute_instance" "mosquitto" {
  name         = "mosquitto-broker"
  machine_type = var.do_mosquitto_size
  zone         = var.do_mosquitto_region

  boot_disk {
    initialize_params {
      image = var.do_mosquitto_image
    }
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.network_interface[0].access_config[0].nat_ip
  }
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update -y",
      "apt install -y mosquitto",
       # Create password file before Mosquitto reads it
      "mosquitto_passwd -b -c /etc/mosquitto/passwd ${var.do_mosquitto_username} ${var.do_mosquitto_password}",

      # Add config file to enforce password auth
      "echo 'allow_anonymous false' > /etc/mosquitto/conf.d/auth.conf",
      "echo 'password_file /etc/mosquitto/passwd' >> /etc/mosquitto/conf.d/auth.conf",
      "systemctl enable mosquitto",
      "systemctl start mosquitto"
    ]
  }

  # This file will include address binding, so connections
  # can be received from anywhere
  provisioner "file" {
    source      = var.mosquitto_config_path
    destination = "/etc/mosquitto/conf.d/mosquitto.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl restart mosquitto",
    ]
  }
  
}

# Assigns the mosquitto droplet to the project

resource "google_dns_record_set" "mqtt" {
  managed_zone = var.gcp_dns_zone
  name         = "mqtt.${var.do_domain}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.mosquitto.network_interface[0].access_config[0].nat_ip]
}

# Create the firewall. Unfortunately, opentofu do provider
# does not support assignment using tags
resource "google_compute_firewall" "mosquitto_fw" {
  name    = "mosquitto-firewall"
  network = var.gcp_network_self_link

  allow {
    protocol = "tcp"
    ports    = ["1883", "8883"]
  }
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}

# These are the outputs
output "mosquitto_host" {
  value = google_compute_instance.mosquitto.network_interface[0].access_config[0].nat_ip
}

output "mosquitto_port" {
  value = 1883
}
