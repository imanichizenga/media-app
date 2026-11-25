terraform {
  required_version = "~> 1.17.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
  # Bucket and key come from: terraform init -backend-config=backend.hcl
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
variable "region" {
  type    = string
  default = "af-south-1" # Cape Town: the closest AWS region to Tanzania
}
variable "zone_id" { type = string }
variable "domain" { type = string }
variable "alarm_emails" {
  type    = set(string)
  default = []
}
variable "sentry_browser_dsn" {
  type    = string
  default = ""
}
provider "aws" {
  region = var.region
  default_tags {
    tags = { project = "news", environment = "prod", managed_by = "terraform" }
  }
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = { project = "news", environment = "prod", managed_by = "terraform" }
  }
}
module "platform" {
  source               = "../../modules/platform"
  providers            = { aws = aws, aws.us_east_1 = aws.us_east_1 }
  environment          = "prod"
  zone_id              = var.zone_id
  api_host             = "api.${var.domain}"
  admin_host           = "admin.${var.domain}"
  media_host           = "media.${var.domain}"
  web_host             = var.domain
  az_count             = 3
  nat_per_az           = true
  db_instance_class    = "db.r8g.xlarge"
  db_allocated_gb      = 200
  db_multi_az          = true
  db_replicas          = 1
  cache_node_type      = "cache.r7g.large"
  cache_shards         = 3
  cache_replicas       = 1
  deletion_protection  = true
  audit_retention_days = 3650
  alarm_emails         = var.alarm_emails
  sentry_browser_dsn   = var.sentry_browser_dsn
  services = {
    api-public      = { cpu = 1024, memory = 2048, min = 3, max = 60 }
    api-admin       = { cpu = 512, memory = 1024, min = 3, max = 4 }
    admin-web       = { cpu = 512, memory = 1024, min = 3, max = 4 }
    web             = { cpu = 1024, memory = 2048, min = 3, max = 40 }
    ws-admin        = { cpu = 256, memory = 1024, min = 2, max = 4 }
    worker-critical = { cpu = 512, memory = 1024, min = 3, max = 10 }
    worker-default  = { cpu = 512, memory = 1024, min = 3, max = 10 }
    worker-media    = { cpu = 2048, memory = 4096, min = 2, max = 20 }
    beat            = { cpu = 256, memory = 512, min = 1, max = 1 }
  }
}
output "platform" { value = module.platform }
