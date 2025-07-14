variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_project_id" {
  description = "Digital ocean project id"
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

variable "do_ssh_key_ids" {
  type = list(string)
}
variable "redis_host" {
  description = "SSH key name"
  type        = string
}

variable "redis_password" {
  description = "SSH key name"
  type        = string
}

provider "digitalocean" {
  token = var.do_access_token
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
resource "digitalocean_droplet" "chirpstack_nodes" {
  count  = var.do_chirpstack_droplet_count
  name   = "chirpstack-node-${count.index + 1}"
  region = var.do_chirpstack_droplet_region
  size   = var.do_chirpstack_droplet_size
  image  = var.do_chirpstack_droplet_image
  ssh_keys = var.do_ssh_key_ids

  tags = ["chirpstack", "ssh"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.ipv4_address
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

resource "digitalocean_project_resources" "assign_droplets" {
  project = var.do_project_id
  resources = [
    for droplet in digitalocean_droplet.chirpstack_nodes : droplet.urn
  ]
}

# Create the firewall.
resource "digitalocean_firewall" "chirpstack_fw" {
  name = "chirpstack-firewall"

  tags = ["chirpstack"]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "udp"
    port_range       = "1700"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol           = "tcp"
    port_range         = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol           = "udp"
    port_range         = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "chirpstack_droplet_ids" {
  value = digitalocean_droplet.chirpstack_nodes[*].id
}