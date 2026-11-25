# Run once per account by an administrator: remote state, and the role GitHub Actions assumes (no stored keys).
terraform {
  required_version = "~> 1.17.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.73"
    }
  }
}
variable "region" {
  type    = string
  default = "af-south-1"
}
variable "environment" { type = string }
variable "github_repository" {
  description = "owner/name"
  type        = string
}
provider "aws" {
  region = var.region
}
data "aws_caller_identity" "this" {}
locals {
  prefix  = "news-${var.environment}"
  account = data.aws_caller_identity.this.account_id
}
resource "aws_s3_bucket" "state" {
  bucket = "${local.prefix}-tfstate-${local.account}"
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
# Deploys images only; it cannot change infrastructure, IAM or data.
resource "aws_iam_role" "deploy" {
  name                 = "${local.prefix}-github-deploy"
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = { StringEquals = {
        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:environment:${var.environment}"
      } }
    }]
  })
}
resource "aws_iam_role_policy" "deploy" {
  role = aws_iam_role.deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "ecr:GetAuthorizationToken", Resource = "*" },
      {
        Effect   = "Allow"
        Action   = ["ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
        Resource = "arn:aws:ecr:${var.region}:${local.account}:repository/${local.prefix}/*"
      },
      # These two actions do not support resource-level permissions.
      { Effect = "Allow", Action = ["ecs:RegisterTaskDefinition", "ecs:DescribeTaskDefinition"], Resource = "*" },
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices", "ecs:RunTask", "ecs:DescribeTasks", "ecs:TagResource"]
        Resource = "arn:aws:ecs:${var.region}:${local.account}:*/${local.prefix}*"
      },
      {
        Effect    = "Allow"
        Action    = "iam:PassRole"
        Resource  = ["arn:aws:iam::${local.account}:role/${local.prefix}-task-*", "arn:aws:iam::${local.account}:role/${local.prefix}-exec-*"]
        Condition = { StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" } }
      },
      # A release names its own stylesheet and script, so the CDN starts again with it. Ids are not known here.
      { Effect = "Allow", Action = "cloudfront:CreateInvalidation", Resource = "arn:aws:cloudfront::${local.account}:distribution/*" },
    ]
  })
}
output "state_bucket" { value = aws_s3_bucket.state.id }
output "deploy_role" { value = aws_iam_role.deploy.arn }
