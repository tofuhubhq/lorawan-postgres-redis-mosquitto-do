variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_project_id" {
  description = "Digital ocean project id"
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

variable "do_mosquitto_name" {
  description = "Mosquitto broker name"
  type        = string
}

variable "do_mosquitto_firewall_name" {
  description = "Mosquitto firewall name"
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

variable "do_ssh_key_name" {
  description = "SSH key name"
  type        = string
}
data "digitalocean_ssh_key" "my_key" {
  name = var.do_ssh_key_name
}

# Provider
provider "digitalocean" {
  token = var.do_access_token
}

resource "digitalocean_droplet" "mosquitto" {
  name   = var.do_mosquitto_name
  region = var.do_mosquitto_region
  size   = var.do_mosquitto_size
  image  = var.do_mosquitto_image
  ssh_keys = [data.digitalocean_ssh_key.my_key.id]

  tags = ["mosquitto", "ssh"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.ipv4_address
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
resource "digitalocean_project_resources" "assign_mosquitto_droplet" {
  project = var.do_project_id
  resources = [digitalocean_droplet.mosquitto.urn]
}

resource "digitalocean_record" "mqtt" {
  domain = var.do_domain                    # "yebomarketplace.com"
  type   = "A"
  name   = "mqtt"                           # This creates mqtt.yebomarketplace.com
  value  = digitalocean_droplet.mosquitto.ipv4_address
}

# Create the firewall. Unfortunately, opentofu do provider
# does not support assignment using tags
resource "digitalocean_firewall" "mosquitto_fw" {
  name = var.do_mosquitto_firewall_name

  tags = ["mosquitto"]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "1883"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8883"
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

# These are the outputs
output "mosquitto_host" {
  value = digitalocean_droplet.mosquitto.ipv4_address
}

output "mosquitto_port" {
  value = 1883
}
