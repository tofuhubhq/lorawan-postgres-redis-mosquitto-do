variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_project_id" {
  description = "Digital ocean project id"
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

provider "digitalocean" {
  token = var.do_access_token
}

# Create a Postgres instance
resource "digitalocean_database_cluster" "postgres" {
  name       = var.do_db_name
  engine     = var.do_db_engine
  version    = var.do_db_version
  size       = var.do_db_size
  region     = var.do_db_region
  node_count = var.do_db_node_count
  project_id = var.do_project_id
}
