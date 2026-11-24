# Uploads go from the browser straight to the bucket, are scanned there, then transcoded (ADR-0025).
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.this["media"].id
  cors_rule {
    allowed_origins = ["https://${var.admin_host}"]
    allowed_methods = ["PUT"]
    allowed_headers = ["content-type"]
    max_age_seconds = 3600
  }
}

# ---- malware scanning ----
data "aws_iam_policy_document" "malware_scan_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["malware-protection-plan.guardduty.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account]
    }
  }
}
resource "aws_iam_role" "malware_scan" {
  name               = "${local.prefix}-malware-scan"
  assume_role_policy = data.aws_iam_policy_document.malware_scan_trust.json
}
resource "aws_iam_role_policy" "malware_scan" {
  role = aws_iam_role.malware_scan.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow", Action = ["events:PutRule", "events:DeleteRule", "events:PutTargets", "events:RemoveTargets"]
        Resource  = "arn:aws:events:${local.region}:${local.account}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
        Condition = { StringLike = { "events:ManagedBy" = "malware-protection-plan.guardduty.amazonaws.com" } }
      },
      {
        Effect   = "Allow", Action = ["events:DescribeRule", "events:ListTargetsByRule"]
        Resource = "arn:aws:events:${local.region}:${local.account}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"
      },
      { Effect = "Allow", Action = ["s3:PutObjectTagging", "s3:GetObjectTagging", "s3:PutObjectVersionTagging", "s3:GetObjectVersionTagging"], Resource = "${aws_s3_bucket.this["media"].arn}/originals/*" },
      { Effect = "Allow", Action = ["s3:PutBucketNotification", "s3:GetBucketNotification", "s3:ListBucket"], Resource = aws_s3_bucket.this["media"].arn },
      { Effect = "Allow", Action = ["s3:PutObject"], Resource = "${aws_s3_bucket.this["media"].arn}/malware-protection-resource-validation-object" },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:GetObjectVersion"], Resource = "${aws_s3_bucket.this["media"].arn}/*" },
    ]
  })
}
resource "aws_guardduty_malware_protection_plan" "media" {
  role = aws_iam_role.malware_scan.arn
  protected_resource {
    s3_bucket {
      bucket_name     = aws_s3_bucket.this["media"].id
      object_prefixes = ["originals/"]
    }
  }
  actions {
    tagging {
      status = "ENABLED"
    }
  }
  depends_on = [aws_iam_role_policy.malware_scan]
}

# ---- transcoding ----
data "aws_iam_policy_document" "mediaconvert_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account]
    }
  }
}
resource "aws_iam_role" "mediaconvert" {
  name               = "${local.prefix}-mediaconvert"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_trust.json
}
resource "aws_iam_role_policy" "mediaconvert" {
  role = aws_iam_role.mediaconvert.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = [for p in ["originals", "probe"] : "${aws_s3_bucket.this["media"].arn}/${p}/*"] },
      { Effect = "Allow", Action = ["s3:PutObject"], Resource = [for p in ["v", "_probe"] : "${aws_s3_bucket.this["media"].arn}/media/${p}/*"] },
    ]
  })
}
