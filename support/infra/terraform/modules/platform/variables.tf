variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}
variable "name" {
  type    = string
  default = "news"
}
variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}
variable "az_count" {
  type    = number
  default = 3
}
variable "nat_per_az" {
  type    = bool
  default = false
}
variable "zone_id" {
  description = "Route 53 hosted zone that contains all hostnames below."
  type        = string
}
variable "api_host" { type = string }
variable "admin_host" { type = string }
variable "media_host" { type = string }
variable "db_instance_class" { type = string }
variable "db_allocated_gb" { type = number }
variable "db_multi_az" { type = bool }
variable "db_replicas" {
  type    = number
  default = 0
}
variable "cache_node_type" { type = string }
variable "cache_shards" {
  type    = number
  default = 1
}
variable "cache_replicas" {
  type    = number
  default = 1
}
variable "services" {
  description = "Task size and scaling per service."
  type = map(object({
    cpu    = number
    memory = number
    min    = number
    max    = number
  }))
}
variable "backlog_per_task" {
  description = "Waiting Celery messages each worker task may have before another is started."
  type        = map(number)
  default     = { worker-critical = 10, worker-default = 100, worker-media = 4 }
}
variable "sentry_browser_dsn" {
  description = "Project that receives the admin console's browser errors. Empty turns reporting off."
  type        = string
  default     = ""
}
variable "image_tag" {
  description = "Used only to create the first task definitions. CI/CD owns later releases."
  type        = string
  default     = "bootstrap"
}
variable "secrets_version" {
  description = "Increase to rotate every generated credential."
  type        = number
  default     = 1
}
variable "audit_retention_days" {
  description = "Object Lock COMPLIANCE retention. It cannot be shortened afterwards, by anyone."
  type        = number
  default     = 3650
}
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "alarm_emails" {
  type    = set(string)
  default = []
}
variable "log_retention_days" {
  type    = number
  default = 90
}
