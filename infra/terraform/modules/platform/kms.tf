locals {
  kms_root = {
    Sid       = "AccountAdministration"
    Effect    = "Allow"
    Principal = { AWS = "arn:aws:iam::${local.account}:root" }
    Action    = "kms:*"
    Resource  = "*"
  }
}
resource "aws_kms_key" "app" {
  description             = "${local.prefix} integration secrets (envelope encryption)"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = jsonencode({ Version = "2012-10-17", Statement = [local.kms_root] })
}
resource "aws_kms_key" "data" {
  description             = "${local.prefix} data at rest"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [local.kms_root, {
      Sid       = "CloudWatchLogs"
      Effect    = "Allow"
      Principal = { Service = "logs.${local.region}.amazonaws.com" }
      Action    = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
      Resource  = "*"
      Condition = { ArnLike = { "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${local.region}:${local.account}:*" } }
      }, {
      Sid       = "CloudWatchAlarms"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
      Resource  = "*"
    }]
  })
}
resource "aws_kms_alias" "this" {
  for_each      = { app = aws_kms_key.app.key_id, data = aws_kms_key.data.key_id }
  name          = "alias/${local.prefix}-${each.key}"
  target_key_id = each.value
}
