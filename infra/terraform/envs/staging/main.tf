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
provider "aws" {
  region = var.region
  default_tags {
    tags = { project = "news", environment = "staging", managed_by = "terraform" }
  }
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = { project = "news", environment = "staging", managed_by = "terraform" }
  }
}
module "platform" {
  source               = "../../modules/platform"
  providers            = { aws = aws, aws.us_east_1 = aws.us_east_1 }
  environment          = "staging"
  zone_id              = var.zone_id
  api_host             = "api.${var.domain}"
  admin_host           = "admin.${var.domain}"
  media_host           = "media.${var.domain}"
  az_count             = 2
  nat_per_az           = false
  db_instance_class    = "db.t4g.large"
  db_allocated_gb      = 50
  db_multi_az          = true
  db_replicas          = 0
  cache_node_type      = "cache.t4g.small"
  cache_shards         = 1
  cache_replicas       = 1
  deletion_protection  = true
  audit_retention_days = 30
  alarm_emails         = var.alarm_emails
  services = {
    api-public      = { cpu = 1024, memory = 2048, min = 1, max = 4 }
    api-admin       = { cpu = 512, memory = 1024, min = 1, max = 4 }
    admin-web       = { cpu = 512, memory = 1024, min = 1, max = 4 }
    ws-admin        = { cpu = 256, memory = 1024, min = 1, max = 4 }
    worker-critical = { cpu = 512, memory = 1024, min = 1, max = 10 }
    worker-default  = { cpu = 512, memory = 1024, min = 1, max = 10 }
    beat            = { cpu = 256, memory = 512, min = 1, max = 1 }
  }
}
output "platform" { value = module.platform }
