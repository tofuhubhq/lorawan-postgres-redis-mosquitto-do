variable "project" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "tier" { type = string }
variable "memory_size_gb" { type = number }

resource "google_redis_instance" "redis" {
  name           = var.name
  tier           = var.tier
  memory_size_gb = var.memory_size_gb
  region         = var.region
}

output "host" { value = google_redis_instance.redis.host }
output "port" { value = google_redis_instance.redis.port }
