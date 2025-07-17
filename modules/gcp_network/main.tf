variable "project" { type = string }
variable "region" { type = string }
variable "network_name" { type = string }

resource "google_compute_network" "main" {
  name                    = var.network_name
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.network_name}-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

output "network" {
  value = google_compute_network.main.name
}
