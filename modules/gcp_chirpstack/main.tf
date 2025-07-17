variable "project" { type = string }
variable "zone" { type = string }
variable "count" { type = number }
variable "machine_type" { type = string }
variable "source_image" { type = string }
variable "network" { type = string }

variable "mosquitto_host" { type = string }
variable "mosquitto_port" { type = number }
variable "mosquitto_username" { type = string }
variable "mosquitto_password" { type = string }

variable "postgres_host" { type = string }
variable "postgres_port" { type = number }
variable "postgres_db_name" { type = string }
variable "postgres_user" { type = string }
variable "postgres_password" { type = string }

variable "redis_host" { type = string }
variable "redis_password" { type = string }

resource "google_compute_instance" "chirpstack" {
  count        = var.count
  name         = "chirpstack-${count.index}" 
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params { image = var.source_image }
  }

  network_interface {
    network = var.network
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose git
    git clone https://github.com/tofuhubhq/chirpstack-docker.git /opt/chirpstack
    cd /opt/chirpstack
    export MQTT_BROKER_HOST=${var.mosquitto_username}:${var.mosquitto_password}@${var.mosquitto_host}
    export POSTGRESQL_HOST=postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:${var.postgres_port}/${var.postgres_db_name}?sslmode=disable
    export REDIS_HOST=default:${var.redis_password}@${var.redis_host}
    docker-compose up -d
  EOT
}

output "instance_self_links" {
  value = google_compute_instance.chirpstack[*].self_link
}
