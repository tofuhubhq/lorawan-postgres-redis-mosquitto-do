
variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}
variable "do_domain" {
  description = "Domain"
  type        = string
}
variable "droplet_ids" {
  description = "List of droplet IDs to attach to the load balancer"
  type        = list(string)
}
variable "do_project_id" {
  description = "Digital ocean project id"
  type        = string
  default     = ""
}
variable "do_chirpstack_droplet_region" {
  description = "Digital ocean droplet region"
  type        = string
  default     = ""
}

variable "domain_depends_on" {
  description = "Dummy variable to enforce domain creation order"
  type        = string
  default     = ""
}

provider "digitalocean" {
  token = var.do_access_token
}
resource "digitalocean_loadbalancer" "chirpstack_lb" {
  name   = "chirpstack-lb"
  region = var.do_chirpstack_droplet_region
  project_id = var.do_project_id

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 8080
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port    = 8080
    target_protocol = "http"

    certificate_id = digitalocean_certificate.lns_tls.id
  }

  healthcheck {
    protocol = "http"
    port     = 8080
    path     = "/"
  }

  redirect_http_to_https = true

  # Not supported yet
  # tls_passthrough = false

  droplet_ids = var.droplet_ids
}

# Create a DNS record pointing to the load balancer
resource "digitalocean_record" "chirpstack_dns" {
  domain = var.do_domain
  type   = "A"
  name   = "lorawan"
  value  = "1.1.1.1"  # Temporary dummy IP
}

resource "digitalocean_certificate" "lns_tls" {
  name = "lns-cert"
  type = "lets_encrypt"

  depends_on = [digitalocean_record.chirpstack_dns]

  domains = ["lorawan5.${var.do_domain}"]
}

resource "digitalocean_record" "chirpstack_dns_update" {
  domain = var.do_domain
  type   = "A"
  name   = "lorawan"
  value  = digitalocean_loadbalancer.chirpstack_lb.ip

  depends_on = [digitalocean_certificate.lns_tls]
}
