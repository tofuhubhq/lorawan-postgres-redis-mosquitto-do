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

variable "do_chirpstack_droplet_count" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_chirpstack_droplet_size" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_chirpstack_droplet_image" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_chirpstack_droplet_region" {
  description = "Digital ocean access token"
  type        = string
}

variable "mosquitto_host" {
  description = "Digital ocean access token"
  type        = string
}

variable "mosquitto_port" {
  description = "Digital ocean access token"
  type        = string
}

variable "mosquitto_username" {
  description = "Digital ocean access token"
  type        = string
}

variable "mosquitto_password" {
  description = "Digital ocean access token"
  type        = string
}

variable "postgres_host" {
  description = "Digital ocean postgres host"
  type        = string
}

variable "postgres_port" {
  description = "Digital ocean postgres port"
  type        = string
}

variable "postgres_db_name" {
  description = "Digital ocean postgres port"
  type        = string
}

variable "postgres_user" {
  description = "Digital ocean postgres port"
  type        = string
}

variable "postgres_password" {
  description = "Digital ocean postgres port"
  type        = string
}

variable "ca_certificate" {
  description = "DigitalOcean CA certificate for secure DB connection"
  type        = string
}

variable "private_key_path" {
  description = "Path to your private SSH key"
  type        = string
}

variable "do_ssh_key_name" {
  description = "SSH key name"
  type        = string
}

variable "redis_host" {
  description = "SSH key name"
  type        = string
}

variable "redis_password" {
  description = "SSH key name"
  type        = string
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}

# File for chirpstack configuration
resource "local_file" "chirpstack_env" {
  filename = "${path.module}/tmp/chirpstack.env"
  content  = <<EOT
  MQTT_BROKER_HOST=${var.mosquitto_username}:${var.mosquitto_password}@${var.mosquitto_host}
  POSTGRESQL_HOST=postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:${var.postgres_port}/${var.postgres_db_name}?sslmode=require
  REDIS_HOST=default:${var.redis_password}@${var.redis_host}
  EOT
}

resource "local_file" "ca_cert" {
  filename = "${path.module}/tmp/ca-certificate.crt"
  content  = var.ca_certificate
}

#@tofuhub:connects_to->postgres
#@tofuhub:connects_to->redis
#@tofuhub:connects_to->mosquitto
resource "google_compute_instance" "chirpstack_nodes" {
  count        = var.do_chirpstack_droplet_count
  name         = "chirpstack-node-${count.index + 1}"
  machine_type = var.do_chirpstack_droplet_size
  zone         = var.do_chirpstack_droplet_region

  boot_disk {
    initialize_params {
      image = var.do_chirpstack_droplet_image
    }
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  # Need to create the directory first, since opentofu does funny stuff otherwise
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/chirpstack"
    ]
  }
  # Copy the local file with the credentials to the remote machine
  provisioner "file" {
    source = local_file.chirpstack_env.filename
    destination = "/var/chirpstack/chirpstack.env"
  }

  # Copy ca certificate from postgres deployment into remote machine
  # to allow for secure connections to the postgres machine 
  provisioner "file" {
    source      = local_file.ca_cert.filename
    destination = "/var/chirpstack/ca-certificate.crt"
  }

  # provisioner "file" {
  #   source = local_file.chirpstack_gateway_env.filename
  #   destination = "/var/chirpstack/chirpstack-gateway-bridge.env"
  # }
  provisioner "remote-exec" {
    # to persist data.
    inline = [
      "apt-get update -y",
      "apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git",
      
      # Install Docker
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list",
      "apt-get update -y",
      "apt-get install -y docker-ce docker-ce-cli containerd.io",

      # Install legacy docker-compose (hyphen version)
      "curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose",
      "ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",

      # Clone Chirpstack
      "git clone https://github.com/tofuhubhq/chirpstack-docker.git /opt/chirpstack",

      # Start containers
      "cd /opt/chirpstack && docker-compose up --build -d"
    ]
  }
}


# Create the firewall.
resource "google_compute_firewall" "chirpstack_fw" {
  name    = "chirpstack-firewall"
  network = var.gcp_network_self_link

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  allow {
    protocol = "udp"
    ports    = ["1700"]
  }
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}

output "chirpstack_droplet_ids" {
  value = google_compute_instance.chirpstack_nodes[*].id
}