variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_vpc_region" {
  description = "Digital ocean vpc region"
  type        = string
}

variable "do_domain" {
  description = "Digital ocean domain"
  type        = string
  default     = ""
}

provider "digitalocean" {
  token = var.do_access_token
}

# Create the VPC. There is no need to assign it to the project,
# because VPCs are not project scoped.
#@tofuhub:protects->chirpstack_nodes
#@tofuhub:protects->mosquitto_broker
#@tofuhub:protects->redis
resource "digitalocean_vpc" "main" {
  name     = "lorawan-vpc"
  region   = var.do_vpc_region
}

# Create the domain
resource "digitalocean_domain" "purus_domain" {
  name = var.do_domain
  # ip   = "203.0.113.10"  # Optional: sets an A record for root domain
}

# Create the SSH firewall
resource "digitalocean_firewall" "ssh" {
  name = "ssh-firewall"

  tags = ["ssh"]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "domain_name" {
  value = digitalocean_domain.purus_domain.name
}

output "domain_resource_id" {
  value = digitalocean_domain.purus_domain.id
}
