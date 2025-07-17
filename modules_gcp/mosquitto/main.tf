variable "gcp_project" {
  type        = string
  description = "GCP project ID"
}

variable "gcp_zone" {
  type        = string
  description = "GCP zone"
}

variable "gcp_credentials" {
  type        = string
  description = "Path to service account json"
  default     = ""
}

variable "mosquitto_instance_name" {
  type        = string
  description = "Name for VM"
}

variable "machine_type" {
  type        = string
  description = "Machine type"
}

variable "mosquitto_username" {
  type        = string
}

variable "mosquitto_password" {
  type        = string
}

provider "google" {
  project     = var.gcp_project
  zone        = var.gcp_zone
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

resource "google_compute_instance" "mosquitto" {
  name         = var.mosquitto_instance_name
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

  tags = ["mosquitto", "ssh"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y mosquitto
    mosquitto_passwd -b -c /etc/mosquitto/passwd "${var.mosquitto_username}" "${var.mosquitto_password}"
    echo "allow_anonymous false" > /etc/mosquitto/conf.d/auth.conf
    echo "password_file /etc/mosquitto/passwd" >> /etc/mosquitto/conf.d/auth.conf
    systemctl restart mosquitto
    systemctl enable mosquitto
  EOT
}

output "mosquitto_host" {
  value = google_compute_instance.mosquitto.network_interface[0].access_config[0].nat_ip
}

output "mosquitto_port" {
  value = 1883
}
