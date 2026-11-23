resource "aws_acm_certificate" "edge" {
  provider                  = aws.us_east_1
  domain_name               = var.api_host
  subject_alternative_names = [var.admin_host, var.media_host]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate" "origin" {
  domain_name               = var.api_host
  subject_alternative_names = [var.admin_host]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
# Both certificates share validation records, which depend only on the hostname and account.
locals {
  validation = { for host in [var.api_host, var.admin_host, var.media_host] : host => one([
    for o in aws_acm_certificate.edge.domain_validation_options : o if o.domain_name == host
  ]) }
}
resource "aws_route53_record" "validation" {
  for_each        = toset([var.api_host, var.admin_host, var.media_host])
  zone_id         = var.zone_id
  name            = local.validation[each.key].resource_record_name
  type            = local.validation[each.key].resource_record_type
  records         = [local.validation[each.key].resource_record_value]
  ttl             = 300
  allow_overwrite = true
}
resource "aws_acm_certificate_validation" "edge" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.edge.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
resource "aws_acm_certificate_validation" "origin" {
  certificate_arn         = aws_acm_certificate.origin.arn
  validation_record_fqdns = [for host in [var.api_host, var.admin_host] : aws_route53_record.validation[host].fqdn]
}

# ---- WAF ----
locals {
  waf_rate = { api = 2000, admin = 600, media = 10000 }
}
resource "aws_wafv2_ip_set" "admin" {
  for_each           = { IPV4 = ["0.0.0.0/1", "128.0.0.0/1"], IPV6 = ["::/1", "8000::/1"] }
  provider           = aws.us_east_1
  name               = "${local.prefix}-admin-${lower(each.key)}"
  scope              = "CLOUDFRONT"
  ip_address_version = each.key
  addresses          = each.value
  lifecycle {
    ignore_changes = [addresses] # owned by the admin console's security settings
  }
}
resource "aws_wafv2_web_acl" "this" {
  for_each = local.waf_rate
  provider = aws.us_east_1
  name     = "${local.prefix}-${each.key}"
  scope    = "CLOUDFRONT"
  default_action {
    allow {}
  }
  dynamic "rule" {
    for_each = each.key == "admin" ? [1] : []
    content {
      name     = "allowlist"
      priority = 0
      action {
        block {}
      }
      statement {
        not_statement {
          statement {
            or_statement {
              dynamic "statement" {
                for_each = aws_wafv2_ip_set.admin
                content {
                  ip_set_reference_statement {
                    arn = statement.value.arn
                  }
                }
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "allowlist"
        sampled_requests_enabled   = true
      }
    }
  }
  rule {
    name     = "rate"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit                 = each.value
        aggregate_key_type    = "IP"
        evaluation_window_sec = 300
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate"
      sampled_requests_enabled   = true
    }
  }
  dynamic "rule" {
    for_each = each.key == "media" ? {} : {
      AWSManagedRulesAmazonIpReputationList = 2
      AWSManagedRulesCommonRuleSet          = 3
      AWSManagedRulesKnownBadInputsRuleSet  = 4
      AWSManagedRulesSQLiRuleSet            = 5
    }
    content {
      name     = rule.key
      priority = rule.value
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.key
          vendor_name = "AWS"
          dynamic "rule_action_override" {
            # Article bodies exceed 8 KB. Django caps request size, and JSON is schema-validated.
            for_each = rule.key == "AWSManagedRulesCommonRuleSet" ? ["SizeRestrictions_BODY"] : []
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.key
        sampled_requests_enabled   = true
      }
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.prefix}-${each.key}"
    sampled_requests_enabled   = true
  }
}

# ---- internal load balancers, published only through CloudFront VPC origins ----
resource "aws_lb" "this" {
  for_each                   = toset(["api", "admin"])
  name                       = "${local.prefix}-${each.key}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [for s in aws_subnet.app : s.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  access_logs {
    bucket  = aws_s3_bucket.this["logs"].id
    prefix  = "alb/${each.key}"
    enabled = true
  }
  depends_on = [aws_s3_bucket_policy.this]
}
resource "aws_lb_target_group" "this" {
  for_each = {
    api-public = { port = 8000, path = "/health/ready" }
    api-admin  = { port = 8000, path = "/health/ready" }
    admin-web  = { port = 3001, path = "/healthz" }
  }
  name                 = "${local.prefix}-${each.key}"
  vpc_id               = aws_vpc.this.id
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  health_check {
    path                = each.value.path
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}
resource "aws_lb_listener" "this" {
  for_each          = aws_lb.this
  load_balancer_arn = each.value.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.origin.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key == "api" ? "api-public" : "admin-web"].arn
  }
}
resource "aws_lb_listener_rule" "admin_api" {
  listener_arn = aws_lb_listener.this["admin"].arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this["api-admin"].arn
  }
  condition {
    path_pattern {
      values = ["/api/v1/*"]
    }
  }
}
resource "aws_cloudfront_vpc_origin" "this" {
  for_each = aws_lb.this
  vpc_origin_endpoint_config {
    name                   = "${local.prefix}-${each.key}"
    arn                    = each.value.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "https-only"
    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

# ---- CloudFront ----
data "aws_cloudfront_cache_policy" "this" {
  for_each = { off = "Managed-CachingDisabled", origin = "UseOriginCacheControlHeaders-QueryStrings", media = "Managed-CachingOptimized" }
  name     = each.value
}
data "aws_cloudfront_origin_request_policy" "viewer" {
  name = "Managed-AllViewerAndCloudFrontHeaders-2022-06"
}
resource "aws_cloudfront_origin_access_control" "media" {
  name                              = "${local.prefix}-media"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_cloudfront_response_headers_policy" "media" {
  name = "${local.prefix}-media"
  security_headers_config {
    content_type_options {
      override = true
    }
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_security_policy {
      content_security_policy = "default-src 'none'; sandbox"
      override                = true
    }
  }
}
resource "aws_cloudfront_distribution" "media" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  aliases         = [var.media_host]
  price_class     = "PriceClass_All" # African edge locations are outside PriceClass_100
  web_acl_id      = aws_wafv2_web_acl.this["media"].arn
  origin {
    origin_id                = "media"
    domain_name              = aws_s3_bucket.this["media"].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.media.id
  }
  default_cache_behavior {
    target_origin_id           = "media"
    viewer_protocol_policy     = "https-only"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.this["media"].id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.media.id
    compress                   = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.edge.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
resource "aws_cloudfront_distribution" "app" {
  for_each        = { api = var.api_host, admin = var.admin_host }
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  aliases         = [each.value]
  price_class     = "PriceClass_All"
  web_acl_id      = aws_wafv2_web_acl.this[each.key].arn
  origin {
    origin_id   = each.key
    domain_name = aws_lb.this[each.key].dns_name
    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.this[each.key].id
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
    # CloudFront needs a stored value here; scripts/sync-origin-secret.sh sets it from Secrets Manager.
    custom_header {
      name  = "X-Origin-Verify"
      value = "unset"
    }
  }
  default_cache_behavior {
    target_origin_id         = each.key
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.this[each.key == "api" ? "origin" : "off"].id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.viewer.id
    compress                 = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.edge.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  lifecycle {
    ignore_changes = [origin] # the header value is rotated outside Terraform so it stays out of state
  }
}
resource "aws_route53_record" "this" {
  for_each = merge(
    { for k, d in aws_cloudfront_distribution.app : "${k}-A" => { name = k == "api" ? var.api_host : var.admin_host, dist = d, type = "A" } },
    { for k, d in aws_cloudfront_distribution.app : "${k}-AAAA" => { name = k == "api" ? var.api_host : var.admin_host, dist = d, type = "AAAA" } },
    { for t in ["A", "AAAA"] : "media-${t}" => { name = var.media_host, dist = aws_cloudfront_distribution.media, type = t } },
  )
  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  alias {
    name                   = each.value.dist.domain_name
    zone_id                = each.value.dist.hosted_zone_id
    evaluate_target_health = false
  }
}
