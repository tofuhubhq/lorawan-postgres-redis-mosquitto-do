variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_credentials_file" {
  description = "Path to the GCP service account JSON credentials"
  type        = string
}

variable "do_vpc_region" {
  description = "(Deprecated) Digital Ocean VPC region"
  type        = string
  default     = ""
}

variable "do_domain" {
  description = "Domain name"
  type        = string
  default     = ""
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}

# Create the VPC. There is no need to assign it to the project,
# because VPCs are not project scoped.
#@tofuhub:protects->chirpstack_nodes
#@tofuhub:protects->mosquitto
#@tofuhub:protects->redis
#@tofuhub:protects->postgres
resource "google_compute_network" "main" {
  name                    = "lorawan-vpc"
  auto_create_subnetworks = true
}

# Create the domain
resource "google_dns_managed_zone" "purus_domain" {
  name     = replace(var.do_domain, ".", "-")
  dns_name = "${var.do_domain}."
}

# Create the SSH firewall
resource "google_compute_firewall" "ssh" {
  name    = "ssh-firewall"
  network = google_compute_network.main.name

  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "domain_name" {
  value = google_dns_managed_zone.purus_domain.dns_name
}

output "domain_resource_id" {
  value = google_dns_managed_zone.purus_domain.id
}
