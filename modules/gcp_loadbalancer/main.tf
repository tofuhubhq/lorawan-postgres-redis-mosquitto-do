variable "project" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "instance_self_links" { type = list(string) }

resource "google_compute_target_pool" "default" {
  name     = var.name
  region   = var.region
  instances = var.instance_self_links
}

resource "google_compute_forwarding_rule" "default" {
  name        = var.name
  region      = var.region
  target      = google_compute_target_pool.default.self_link
  port_range  = "80"
}

output "ip" {
  value = google_compute_forwarding_rule.default.ip_address
}
