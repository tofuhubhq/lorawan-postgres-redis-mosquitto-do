terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Digital Ocean
variable "do_domain" {
  description = "Digital ocean domain"
  type        = string
  default     = ""
}

variable "do_access_token" {
  description = "Digital ocean access token"
  type        = string
  default     = ""
}

variable "do_project_name" {
  description = "Digital ocean project name"
  type        = string
  default     = ""
}

variable "do_project_description" {
  description = "Digital ocean project description"
  type        = string
  default     = ""
}

variable "do_vpc_region" {
  description = "Digital ocean vpc region"
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

# Mosquitto vars
variable "do_mosquitto_region" {
  description = "Digital ocean mosquitto region"
  type        = string
}

variable "do_mosquitto_image" {
  description = "Digital ocean mosquitto image"
  type        = string
}

variable "do_mosquitto_size" {
  description = "Digital ocean mosquitto size"
  type        = string
}

variable "do_mosquitto_username" {
  description = "Digital ocean mosquitto username"
  type        = string
}

variable "do_mosquitto_password" {
  description = "Digital ocean mosquitto password"
  type        = string
}

# Chirpstack vars
variable "do_chirpstack_droplet_count" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_chirpstack_droplet_size" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_chirpstack_droplet_image" {
  description = "Digital ocean access token"
  type        = string
}

variable "do_chirpstack_droplet_region" {
  description = "Digital ocean access token"
  type        = string
}

# SSH config
variable "private_key_path" {
  description = "Path to your private SSH key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "do_ssh_key_name" {
  description = "SSH key name"
  type        = string
}

data "digitalocean_ssh_key" "my_key" {
  name = var.do_ssh_key_name
}

# Providers

provider "digitalocean" {
  token = var.do_access_token
}

# Create project
resource "digitalocean_project" "playground" {
  name        = var.do_project_name
  description = var.do_project_description
  purpose     = "Web Application"
  environment = "Development"
}

# WORKING
# Create the network
module "network" {
  source = "./modules/network"
  do_access_token = var.do_access_token
  do_vpc_region  = var.do_vpc_region
  do_domain = var.do_domain
}

# WORKING
# Create the postgres db
module "postgres" {
  source = "./modules/postgres"
  do_access_token = var.do_access_token
  do_project_id     = digitalocean_project.playground.id
  do_db_name       = var.do_db_name
  do_db_engine     = var.do_db_engine
  do_db_version    = var.do_db_version
  do_db_size       = var.do_db_size
  do_db_region     = var.do_db_region
  do_db_node_count = var.do_db_node_count
}

# Create the mosquitto broker
module "mosquitto" {
  source = "./modules/mosquitto"
  do_access_token = var.do_access_token
  do_mosquitto_image = var.do_mosquitto_image
  do_mosquitto_size = var.do_mosquitto_size
  do_mosquitto_region = var.do_mosquitto_region
  private_key_path = var.private_key_path
  do_project_id = digitalocean_project.playground.id
  do_ssh_key_name = var.do_ssh_key_name
  do_domain = var.do_domain
  mosquitto_config_path = "${path.module}/modules/mosquitto/mosquitto.conf"
  do_mosquitto_username = var.do_mosquitto_username
  do_mosquitto_password = var.do_mosquitto_password
}

module "chirpstack" {
  source = "./modules/chirpstack"
  do_access_token = var.do_access_token
  do_chirpstack_droplet_count = var.do_chirpstack_droplet_count
  do_chirpstack_droplet_size = var.do_chirpstack_droplet_size
  do_chirpstack_droplet_image = var.do_chirpstack_droplet_image
  do_chirpstack_droplet_region = var.do_chirpstack_droplet_region
  private_key_path = var.private_key_path
  do_ssh_key_name = var.do_ssh_key_name
  do_project_id = digitalocean_project.playground.id

  # These are the variables that are coming from the mosquitto module
  mosquitto_host     = module.mosquitto.mosquitto_host
  mosquitto_port     = module.mosquitto.mosquitto_port
  mosquitto_username = var.do_mosquitto_username
  mosquitto_password = var.do_mosquitto_password

  postgres_host     = module.postgres.postgres_credentials.host
  postgres_port     = module.postgres.postgres_credentials.port
  postgres_db_name  = module.postgres.postgres_credentials.db_name
  postgres_user     = module.postgres.postgres_credentials.user
  postgres_password = module.postgres.postgres_credentials.password

  ca_certificate = module.postgres.ca_certificate
}

module "loadbalancer" {
  source = "./modules/loadbalancer"
  do_project_id = digitalocean_project.playground.id
  do_chirpstack_droplet_region = var.do_chirpstack_droplet_region
  droplet_ids = module.chirpstack.chirpstack_droplet_ids
  do_domain = var.do_domain
  do_access_token = var.do_access_token
}