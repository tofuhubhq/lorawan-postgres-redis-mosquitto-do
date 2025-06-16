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

variable "do_db_name" {
  description = "Digital ocean db name"
  type        = string
}

variable "do_db_engine" {
  description = "Digital ocean db engine"
  type        = string
}

variable "do_db_version" {
  description = "Digital ocean db version"
  type        = string
}

variable "do_db_size" {
  description = "Digital ocean db size"
  type        = string
}

variable "do_db_region" {
  description = "Digital ocean db region"
  type        = string
}

variable "do_db_node_count" {
  description = "Digital ocean db node count"
  type        = string
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}

resource "google_sql_database_instance" "postgres" {
  name             = var.do_db_name
  database_version = var.do_db_version
  region           = var.gcp_region

  settings {
    tier = var.do_db_size
  }
}

# Create the pg_trgm extension
resource "null_resource" "enable_pg_trgm" {
  depends_on = [
    google_sql_database_instance.postgres
  ]
  provisioner "local-exec" {
    command = "echo 'create extension pg_trgm;'"
  }
}



output "postgres_credentials" {
  value = {
    host     = google_sql_database_instance.postgres.public_ip_address
    port     = 5432
    user     = "postgres"
    password = ""
    uri      = google_sql_database_instance.postgres.self_link
    db_name  = var.do_db_name
  }
  sensitive = true
}