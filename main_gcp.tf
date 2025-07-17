terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "gcp_project" { type = string }
variable "gcp_region" { type = string }
variable "gcp_zone" { type = string }
variable "gcp_credentials" { type = string default = "" }

variable "db_name" { type = string }
variable "db_tier" { type = string }

variable "redis_password" { type = string }
variable "mosquitto_username" { type = string }
variable "mosquitto_password" { type = string }

variable "machine_type" { type = string }
variable "instance_count" { type = number default = 2 }

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = var.gcp_credentials == "" ? null : file(var.gcp_credentials)
}

module "network" {
  source              = "./modules_gcp/network"
  gcp_project         = var.gcp_project
  gcp_region          = var.gcp_region
  gcp_credentials     = var.gcp_credentials
  gcp_vpc_name        = "lorawan-vpc"
  gcp_domain          = ""
  gcp_ssh_firewall_name = "ssh-fw"
}

module "postgres" {
  source          = "./modules_gcp/postgres"
  gcp_project     = var.gcp_project
  gcp_region      = var.gcp_region
  gcp_credentials = var.gcp_credentials
  db_name         = var.db_name
  db_tier         = var.db_tier
}

module "redis" {
  source             = "./modules_gcp/redis"
  gcp_project        = var.gcp_project
  gcp_zone           = var.gcp_zone
  gcp_credentials    = var.gcp_credentials
  redis_instance_name = "redis"
  machine_type       = var.machine_type
  redis_password     = var.redis_password
}

module "mosquitto" {
  source                = "./modules_gcp/mosquitto"
  gcp_project           = var.gcp_project
  gcp_zone              = var.gcp_zone
  gcp_credentials       = var.gcp_credentials
  mosquitto_instance_name = "mosquitto"
  machine_type          = var.machine_type
  mosquitto_username    = var.mosquitto_username
  mosquitto_password    = var.mosquitto_password
}

module "chirpstack" {
  source          = "./modules_gcp/chirpstack"
  gcp_project     = var.gcp_project
  gcp_zone        = var.gcp_zone
  gcp_credentials = var.gcp_credentials
  machine_type    = var.machine_type
  instance_count  = var.instance_count

  mosquitto_host     = module.mosquitto.mosquitto_host
  mosquitto_port     = module.mosquitto.mosquitto_port
  mosquitto_username = var.mosquitto_username
  mosquitto_password = var.mosquitto_password

  postgres_host     = module.postgres.postgres_credentials.host
  postgres_db_name  = module.postgres.postgres_credentials.db_name
  postgres_user     = module.postgres.postgres_credentials.user
  postgres_password = module.postgres.postgres_credentials.password

  redis_host     = module.redis.redis_host
  redis_password = module.redis.redis_password
}

# Load balancer setup (optional)
# module "loadbalancer" {
#   source          = "./modules_gcp/loadbalancer"
#   gcp_project     = var.gcp_project
#   gcp_region      = var.gcp_region
#   gcp_credentials = var.gcp_credentials
#   lb_name         = "chirpstack-lb"
#   instance_group  = google_compute_instance_group.default.self_link
# }
