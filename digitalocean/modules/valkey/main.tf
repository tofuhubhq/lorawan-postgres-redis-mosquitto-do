variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "valkey_droplet_size" {
  description = "Droplet size for Valkey"
  type        = string
  default     = ""
}

variable "valkey_droplet_image" {
  description = "Image for Valkey Droplet"
  type        = string
  default     = ""
}

variable "valkey_region" {
  description = "Region for Valkey Droplet"
  type        = string
}

variable "valkey_password" {
  description = "Password to secure Valkey"
  type        = string
}

variable "private_key_path" {
  description = "Path to your SSH private key"
  type        = string
}

variable "do_ssh_key_name" {
  description = "SSH key name for Valkey droplet"
  type        = string
}

provider "digitalocean" {
  token = var.do_access_token
}

data "digitalocean_ssh_key" "valkey_key" {
  name = var.do_ssh_key_name
}

resource "digitalocean_droplet" "valkey" {
  name   = "valkey"
  region = var.valkey_region
  size   = var.valkey_droplet_size
  image  = var.valkey_droplet_image
  ssh_keys = [data.digitalocean_ssh_key.valkey_key.id]
  tags     = ["valkey"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "apt update -y",
      "apt install -y valkey-server",
      "sed -i 's/^# requirepass .*/requirepass ${var.valkey_password}/' /etc/valkey/valkey.conf",
      "systemctl restart valkey-server"
    ]
  }
}

# TODO: add firewall
# resource "digitalocean_firewall" "valkey_fw" {
#   name = "valkey-firewall"

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "6379"
#     source_addresses = ["${var.allowed_chirpstack_ips}"] # OR hardcode trusted IPs
#   }

#   outbound_rule {
#     protocol              = "tcp"
#     port_range            = "all"
#     destination_addresses = ["0.0.0.0/0", "::/0"]
#   }

#   droplet_ids = [digitalocean_droplet.valkey.id]
# }

output "valkey_host" {
  value = digitalocean_droplet.valkey.ipv4_address
}

output "valkey_port" {
  value = "6379"
}

output "valkey_password" {
  value = var.valkey_password
  sensitive = true
}

