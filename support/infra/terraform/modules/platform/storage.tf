locals {
  buckets = {
    media = "${local.prefix}-media-${local.account}"
    audit = "${local.prefix}-audit-${local.account}"
    logs  = "${local.prefix}-logs-${local.account}"
  }
}
resource "aws_s3_bucket" "this" {
  for_each            = local.buckets
  bucket              = each.value
  object_lock_enabled = each.key == "audit"
}
resource "aws_s3_bucket_public_access_block" "this" {
  for_each                = aws_s3_bucket.this
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each   = { for k, b in aws_s3_bucket.this : k => b if k != "audit" }
  bucket     = each.value.id
  depends_on = [aws_s3_bucket_versioning.this]
  rule {
    id     = "housekeeping"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    dynamic "expiration" {
      for_each = each.key == "logs" ? [1] : []
      content {
        days = 400
      }
    }
  }
  dynamic "rule" {
    for_each = each.key == "media" ? [1] : []
    content {
      id     = "originals"
      status = "Enabled"
      filter {
        prefix = "originals/"
      }
      transition {
        days          = 30
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  }
  dynamic "rule" {
    for_each = each.key == "media" ? toset(["probe/", "media/_probe/"]) : []
    content {
      id     = "expire-${replace(rule.value, "/", "-")}"
      status = "Enabled"
      filter {
        prefix = rule.value
      }
      expiration {
        days = 1
      }
    }
  }
}
resource "aws_s3_bucket_object_lock_configuration" "audit" {
  bucket     = aws_s3_bucket.this["audit"].id
  depends_on = [aws_s3_bucket_versioning.this]
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.audit_retention_days
    }
  }
}
data "aws_iam_policy_document" "bucket" {
  for_each = aws_s3_bucket.this
  statement {
    sid       = "TlsOnly"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [each.value.arn, "${each.value.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  dynamic "statement" {
    for_each = each.key == "media" ? [1] : []
    content {
      sid       = "CloudFrontOac"
      actions   = ["s3:GetObject"]
      resources = ["${each.value.arn}/media/*"] # originals/ are never served
      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [aws_cloudfront_distribution.media.arn]
      }
    }
  }
  # Not even our own code can open an original before its scan came back clean.
  dynamic "statement" {
    for_each = each.key == "media" ? [1] : []
    content {
      sid       = "NoReadUnlessClean"
      effect    = "Deny"
      actions   = ["s3:GetObject", "s3:GetObjectVersion"]
      resources = ["${each.value.arn}/originals/*"]
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      condition {
        test     = "StringNotEquals"
        variable = "s3:ExistingObjectTag/GuardDutyMalwareScanStatus"
        values   = ["NO_THREATS_FOUND"]
      }
      condition {
        test     = "ArnNotEquals"
        variable = "aws:PrincipalArn"
        values   = [aws_iam_role.malware_scan.arn]
      }
    }
  }
  dynamic "statement" {
    for_each = each.key == "media" ? [1] : []
    content {
      sid       = "OnlyTheScannerGivesVerdicts"
      effect    = "Deny"
      actions   = ["s3:PutObjectTagging", "s3:PutObjectVersionTagging", "s3:DeleteObjectTagging", "s3:DeleteObjectVersionTagging"]
      resources = ["${each.value.arn}/*"]
      principals {
        type        = "*"
        identifiers = ["*"]
      }
      condition {
        test     = "ArnNotEquals"
        variable = "aws:PrincipalArn"
        values   = [aws_iam_role.malware_scan.arn]
      }
    }
  }
  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []
    content {
      sid       = "AlbAccessLogs"
      actions   = ["s3:PutObject"]
      resources = ["${each.value.arn}/alb/*"]
      principals {
        type        = "Service"
        identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [local.account]
      }
    }
  }
}
resource "aws_s3_bucket_policy" "this" {
  for_each   = aws_s3_bucket.this
  bucket     = each.value.id
  policy     = data.aws_iam_policy_document.bucket[each.key].json
  depends_on = [aws_s3_bucket_public_access_block.this]
}
