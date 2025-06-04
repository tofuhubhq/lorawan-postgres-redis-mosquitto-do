variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_project_id" {
  description = "Digital ocean project id"
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
    "bash -c 'set -eux && while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo \"Waiting for apt lock...\"; sleep 3; done && apt-get update -y || true && apt-get install -y redis-server && sed -i \"s/^#\\?\\s*bind .*/bind 0.0.0.0/\" /etc/redis/redis.conf && sed -i \"s/^#\\?\\s*protected-mode .*/protected-mode no/\" /etc/redis/redis.conf && sed -i \"s/^#\\?\\s*requirepass .*/requirepass ${var.valkey_password}/\" /etc/redis/redis.conf && systemctl enable redis-server && systemctl restart redis-server'"
  ]
}


}

resource "digitalocean_firewall" "valkey_fw" {
  name = "valkey-firewall"

  inbound_rule {
    protocol         = "tcp"
    port_range       = "6379"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  droplet_ids = [digitalocean_droplet.valkey.id]
}

# Assigns the mosquitto droplet to the project
resource "digitalocean_project_resources" "assign_valkey_droplet" {
  project = var.do_project_id
  resources = [digitalocean_droplet.valkey.urn]
}

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

