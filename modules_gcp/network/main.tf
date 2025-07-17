variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_credentials" {
  description = "Path to GCP service account key JSON"
  type        = string
  default     = ""
}

variable "gcp_vpc_name" {
  description = "GCP VPC network name"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_domain" {
  description = "Domain (managed zone must exist)"
  type        = string
  default     = ""
}

variable "gcp_ssh_firewall_name" {
  description = "SSH firewall name"
  type        = string
  default     = ""
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

# Create the VPC network
resource "google_compute_network" "main" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = true
}

# Optional: reference an existing managed zone. The zone must already exist
data "google_dns_managed_zone" "zone" {
  count = var.gcp_domain == "" ? 0 : 1
  name  = var.gcp_domain
}

resource "google_compute_firewall" "ssh" {
  name    = var.gcp_ssh_firewall_name
  network = google_compute_network.main.self_link

  target_tags = ["ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

output "network_name" {
  value = google_compute_network.main.name
}
