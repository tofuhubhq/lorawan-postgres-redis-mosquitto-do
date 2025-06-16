
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
variable "gcp_dns_zone" {
  description = "Name of the managed DNS zone"
  type        = string
}
variable "do_domain" {
  description = "Domain"
  type        = string
}
variable "gcp_target_proxy" {
  description = "Target proxy for forwarding rule"
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

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}

#@tofuhub:connects_to->redis
# Placeholder for Google Cloud load balancer setup
resource "google_compute_forwarding_rule" "chirpstack_lb" {
  name       = "chirpstack-lb"
  target     = var.gcp_target_proxy
  port_range = "80-80"
}
