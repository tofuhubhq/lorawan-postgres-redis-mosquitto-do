variable "gcp_project" { type = string }
variable "gcp_region" { type = string }
variable "gcp_credentials" { type = string default = "" }
variable "instance_group" { type = string }
variable "lb_name" { type = string }

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

resource "google_compute_health_check" "http" {
  name               = "${var.lb_name}-hc"
  check_interval_sec = 5
  timeout_sec        = 5
  http_health_check {
    port = 8080
    request_path = "/"
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "${var.lb_name}-backend"
  health_checks         = [google_compute_health_check.http.self_link]
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 10
  backend {
    group = var.instance_group
  }
}

resource "google_compute_url_map" "default" {
  name            = "${var.lb_name}-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.lb_name}-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = var.lb_name
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.default.ip_address
}
