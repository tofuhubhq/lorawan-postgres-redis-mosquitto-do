variable "project" { type = string }
variable "region" { type = string }
variable "db_name" { type = string }
variable "db_version" { type = string }
variable "tier" { type = string }
variable "db_password" { type = string }

resource "google_sql_database_instance" "postgres" {
  name             = var.db_name
  database_version = var.db_version
  region           = var.region

  settings {
    tier = var.tier
  }

  deletion_protection = false
  root_password       = var.db_password
}

resource "google_sql_database" "default" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

output "host" {
  value = google_sql_database_instance.postgres.ip_address[0].ip_address
}

output "port" { value = 5432 }
output "user" { value = "postgres" }
output "password" { value = var.db_password }
output "db_name" { value = var.db_name }
