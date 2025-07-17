variable "gcp_project" {
  type = string
}

variable "gcp_zone" {
  type = string
}

variable "gcp_credentials" {
  type    = string
  default = ""
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "machine_type" {
  type = string
}

variable "mosquitto_host" { type = string }
variable "mosquitto_port" { type = string }
variable "mosquitto_username" { type = string }
variable "mosquitto_password" { type = string }

variable "postgres_host" { type = string }
variable "postgres_db_name" { type = string }
variable "postgres_user" { type = string }
variable "postgres_password" { type = string }

variable "redis_host" { type = string }
variable "redis_password" { type = string }

provider "google" {
  project     = var.gcp_project
  zone        = var.gcp_zone
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

resource "google_compute_instance" "chirpstack" {
  count        = var.instance_count
  name         = "chirpstack-${count.index}"
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params { image = "ubuntu-os-cloud/ubuntu-2204-lts" }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["chirpstack", "ssh"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose git
    git clone https://github.com/tofuhubhq/chirpstack-docker.git /opt/chirpstack
    cat <<EOM >/opt/chirpstack/.env
MQTT_BROKER_HOST=${var.mosquitto_username}:${var.mosquitto_password}@${var.mosquitto_host}
POSTGRESQL_HOST=postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_db_name}
REDIS_HOST=default:${var.redis_password}@${var.redis_host}
EOM
    cd /opt/chirpstack
    docker-compose up -d
  EOT
}

output "chirpstack_ips" {
  value = [for i in google_compute_instance.chirpstack : i.network_interface[0].access_config[0].nat_ip]
}
