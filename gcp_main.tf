terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

variable "gcp_project" { type = string }
variable "gcp_region" { type = string }
variable "gcp_zone" { type = string }

variable "network_name" { type = string }

variable "db_name" { type = string }
variable "db_version" { type = string }
variable "db_tier" { type = string }
variable "db_password" { type = string }

variable "redis_name" { type = string }
variable "redis_tier" { type = string }
variable "redis_memory_size_gb" { type = number }

variable "mosquitto_name" { type = string }
variable "mosquitto_machine_type" { type = string }
variable "mosquitto_image" { type = string }
variable "mosquitto_username" { type = string }
variable "mosquitto_password" { type = string }

variable "chirpstack_count" { type = number }
variable "chirpstack_machine_type" { type = string }
variable "chirpstack_image" { type = string }

variable "loadbalancer_name" { type = string }

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

module "network" {
  source       = "./modules/gcp_network"
  project      = var.gcp_project
  region       = var.gcp_region
  network_name = var.network_name
}

module "postgres" {
  source      = "./modules/gcp_postgres"
  project     = var.gcp_project
  region      = var.gcp_region
  db_name     = var.db_name
  db_version  = var.db_version
  tier        = var.db_tier
  db_password = var.db_password
}

module "redis" {
  source          = "./modules/gcp_redis"
  project         = var.gcp_project
  region          = var.gcp_region
  name            = var.redis_name
  tier            = var.redis_tier
  memory_size_gb  = var.redis_memory_size_gb
}

module "mosquitto" {
  source        = "./modules/gcp_mosquitto"
  project       = var.gcp_project
  zone          = var.gcp_zone
  name          = var.mosquitto_name
  machine_type  = var.mosquitto_machine_type
  source_image  = var.mosquitto_image
  network       = module.network.network
  username      = var.mosquitto_username
  password      = var.mosquitto_password
}

module "chirpstack" {
  source            = "./modules/gcp_chirpstack"
  project           = var.gcp_project
  zone              = var.gcp_zone
  count             = var.chirpstack_count
  machine_type      = var.chirpstack_machine_type
  source_image      = var.chirpstack_image
  network           = module.network.network
  mosquitto_host    = module.mosquitto.mosquitto_host
  mosquitto_port    = module.mosquitto.mosquitto_port
  mosquitto_username = var.mosquitto_username
  mosquitto_password = var.mosquitto_password
  postgres_host     = module.postgres.host
  postgres_port     = module.postgres.port
  postgres_db_name  = module.postgres.db_name
  postgres_user     = module.postgres.user
  postgres_password = module.postgres.password
  redis_host        = module.redis.host
}

module "loadbalancer" {
  source              = "./modules/gcp_loadbalancer"
  project             = var.gcp_project
  region              = var.gcp_region
  name                = var.loadbalancer_name
  instance_self_links = module.chirpstack.instance_self_links
}

