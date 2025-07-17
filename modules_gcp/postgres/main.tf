variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_credentials" {
  description = "Path to service account json"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_tier" {
  description = "Instance tier"
  type        = string
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

resource "google_sql_database_instance" "postgres" {
  name             = var.db_name
  database_version = "POSTGRES_15"
  region           = var.gcp_region

  settings {
    tier = var.db_tier
  }
}

resource "google_sql_database" "db" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "dbuser" {
  name     = "chirpstack"
  instance = google_sql_database_instance.postgres.name
  password = random_password.password.result
}

resource "random_password" "password" {
  length  = 16
  special = false
}

output "postgres_credentials" {
  value = {
    host     = google_sql_database_instance.postgres.connection_name
    user     = google_sql_user.dbuser.name
    password = random_password.password.result
    db_name  = google_sql_database.db.name
  }
  sensitive = true
}
