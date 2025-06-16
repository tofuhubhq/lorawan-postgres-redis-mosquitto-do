terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Google Cloud configuration
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

# redis
variable "redis_droplet_size" {
  description = "Droplet size for redis"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "redis_droplet_image" {
  description = "Image for redis Droplet"
  type        = string
  default     = "ubuntu-22-04-x64"
}

variable "redis_region" {
  description = "Region for redis Droplet"
  type        = string
}

variable "redis_password" {
  description = "Password to secure redis"
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



# Providers

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.gcp_project
  region      = var.gcp_region
}


module "network" {
  source               = "./modules/network"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_credentials_file = var.gcp_credentials_file
  do_domain            = var.do_domain
}

module "redis" {
  source               = "./modules/redis"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_credentials_file = var.gcp_credentials_file
  gcp_network_self_link = module.network.domain_resource_id
  redis_droplet_size   = var.redis_droplet_size
  redis_droplet_image  = var.redis_droplet_image
  redis_region         = var.redis_region
  redis_password       = var.redis_password
  private_key_path     = var.private_key_path
}

  source               = "./modules/postgres"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_credentials_file = var.gcp_credentials_file
  do_db_name       = var.do_db_name
  do_db_engine     = var.do_db_engine
  do_db_version    = var.do_db_version
  do_db_size       = var.do_db_size
  do_db_region     = var.do_db_region
  do_db_node_count = var.do_db_node_count
}
module "mosquitto" {
  source               = "./modules/mosquitto"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_credentials_file = var.gcp_credentials_file
  gcp_network_self_link = module.network.domain_resource_id
  gcp_dns_zone         = module.network.domain_name
  do_mosquitto_image   = var.do_mosquitto_image
  do_mosquitto_size    = var.do_mosquitto_size
  do_mosquitto_region  = var.do_mosquitto_region
  private_key_path     = var.private_key_path
  do_domain            = var.do_domain
  mosquitto_config_path = "${path.module}/modules/mosquitto/mosquitto.conf"
  do_mosquitto_username = var.do_mosquitto_username
  do_mosquitto_password = var.do_mosquitto_password
}

module "chirpstack" {
  source               = "./modules/chirpstack"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_credentials_file = var.gcp_credentials_file
  do_chirpstack_droplet_count = var.do_chirpstack_droplet_count
  do_chirpstack_droplet_size  = var.do_chirpstack_droplet_size
  do_chirpstack_droplet_image = var.do_chirpstack_droplet_image
  do_chirpstack_droplet_region = var.do_chirpstack_droplet_region
  private_key_path = var.private_key_path

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

  redis_host = module.redis.redis_host
  redis_password = module.redis.redis_password
  
  ca_certificate = module.postgres.ca_certificate
}

module "loadbalancer" {
  source               = "./modules/loadbalancer"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_credentials_file = var.gcp_credentials_file
  gcp_dns_zone         = module.network.domain_name
  gcp_target_proxy     = "" # TODO: configure target proxy
  droplet_ids          = module.chirpstack.chirpstack_droplet_ids
  do_domain            = module.network.domain_name
  domain_depends_on    = module.network.domain_resource_id
}