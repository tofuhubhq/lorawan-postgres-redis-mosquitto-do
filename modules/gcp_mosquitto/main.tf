variable "project" { type = string }
variable "zone" { type = string }
variable "name" { type = string }
variable "machine_type" { type = string }
variable "source_image" { type = string }
variable "network" { type = string }
variable "username" { type = string }
variable "password" { type = string }

resource "google_compute_instance" "mosquitto" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.source_image
    }
  }

  network_interface {
    network = var.network
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y mosquitto
    mosquitto_passwd -b -c /etc/mosquitto/passwd ${var.username} ${var.password}
    echo "allow_anonymous false" > /etc/mosquitto/conf.d/auth.conf
    echo "password_file /etc/mosquitto/passwd" >> /etc/mosquitto/conf.d/auth.conf
    systemctl enable mosquitto
    systemctl restart mosquitto
  EOT
}

output "mosquitto_host" { value = google_compute_instance.mosquitto.network_interface[0].access_config[0].nat_ip }
output "mosquitto_port" { value = 1883 }
