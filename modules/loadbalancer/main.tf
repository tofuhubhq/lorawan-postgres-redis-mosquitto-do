
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

variable "do_loadbalancer_name" {
  description = "Digital ocean loadbalancer name"
  type        = string
  default     = ""
}

variable "domain_depends_on" {
  description = "Dummy variable to enforce domain creation order"
  type        = string
  default     = ""
}

variable "do_lorawan_subdomain" {
  description = "Lorawan subdomain"
  type        = string
  default     = ""
}

provider "digitalocean" {
  token = var.do_access_token
}

resource "digitalocean_loadbalancer" "chirpstack_lb" {
  name       = var.do_loadbalancer_name
  region     = var.do_chirpstack_droplet_region
  project_id = var.do_project_id
  droplet_ids = var.droplet_ids

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"
    target_port    = 8080
    target_protocol = "http"
  }

  healthcheck {
    protocol = "http"
    port     = 8080
    path     = "/"
  }

  redirect_http_to_https = false
}

resource "digitalocean_record" "chirpstack_dns" {
  domain = var.do_domain
  type   = "A"
  name   = var.do_lorawan_subdomain
  value  = digitalocean_loadbalancer.chirpstack_lb.ip

  depends_on = [digitalocean_loadbalancer.chirpstack_lb]
}

# Wait for DNS to propagate + create cert via doctl
resource "null_resource" "create_tls_cert" {
  depends_on = [digitalocean_record.chirpstack_dns]

  provisioner "local-exec" {
    environment = {
      DIGITALOCEAN_ACCESS_TOKEN = var.do_access_token
    }

    command = <<EOT
bash -c '
echo "🔍 Waiting for DNS to propagate..."
for i in {1..30}; do
  resolved_ip=$(dig +short ${var.do_lorawan_subdomain}.${var.do_domain})
  echo "Resolved: $resolved_ip"
  if [ "$resolved_ip" = "${digitalocean_loadbalancer.chirpstack_lb.ip}" ]; then
    echo "✅ DNS OK"
    break
  fi
  sleep 10
done

echo "📜 Creating TLS cert via doctl..."
doctl compute certificate create lns-cert-${var.do_lorawan_subdomain} --type lets_encrypt --dns-names ${var.do_lorawan_subdomain}.${var.do_domain}
'
EOT
  }
}