variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_project_id" {
  description = "Digital ocean project id"
  type        = string
}
variable "redis_droplet_size" {
  description = "Droplet size for redis"
  type        = string
  default     = ""
}

variable "redis_droplet_name" {
  description = "Name for redis Droplet"
  type        = string
  default     = ""
}

variable "redis_droplet_image" {
  description = "Image for redis Droplet"
  type        = string
  default     = ""
}

variable "redis_region" {
  description = "Region for redis Droplet"
  type        = string
}

variable "redis_password" {
  description = "Password to secure redis"
  type        = string
}

variable "do_ssh_key_ids" {
  type = list(string)
}

variable "private_key_path" {
  description = "Path to your SSH private key"
  type        = string
}

provider "digitalocean" {
  token = var.do_access_token
}
resource "digitalocean_droplet" "redis" {
  name   = var.redis_droplet_name
  region = var.redis_region
  size   = var.redis_droplet_size
  image  = var.redis_droplet_image
  ssh_keys = var.do_ssh_key_ids
  tags     = ["redis", "ssh"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_path)
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
  inline = [
    "bash -c 'set -eux && while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo \"Waiting for apt lock...\"; sleep 3; done && apt-get update -y || true && apt-get install -y redis-server && sed -i \"s/^#\\?\\s*bind .*/bind 0.0.0.0/\" /etc/redis/redis.conf && sed -i \"s/^#\\?\\s*protected-mode .*/protected-mode no/\" /etc/redis/redis.conf && sed -i \"s/^#\\?\\s*requirepass .*/requirepass ${var.redis_password}/\" /etc/redis/redis.conf && systemctl enable redis-server && systemctl restart redis-server'"
    ]
  }
}

#@tofuhub:is_used_by->redis_resource
resource "digitalocean_firewall" "redis_fw" {
  name = "redis-firewall"

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

  droplet_ids = [digitalocean_droplet.redis.id]
}

# Assigns the mosquitto droplet to the project
resource "digitalocean_project_resources" "assign_redis_droplet" {
  project = var.do_project_id
  resources = [digitalocean_droplet.redis.urn]
}

output "redis_host" {
  value = digitalocean_droplet.redis.ipv4_address
}

output "redis_port" {
  value = "6379"
}

output "redis_password" {
  value = var.redis_password
  sensitive = true
}

