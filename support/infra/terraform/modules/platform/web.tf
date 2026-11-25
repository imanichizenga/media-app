# The readers' website (ADR-0047): ECS behind CloudFront, beside the API, with a cache of its own.

# The website asks the API inside the network, never through its CDN: after a purge it must not read an old answer.
resource "aws_route53_zone" "internal" {
  name = var.api_host
  vpc {
    vpc_id = aws_vpc.this.id
  }
}
resource "aws_route53_record" "internal_api" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.api_host
  type    = "A"
  alias {
    name                   = aws_lb.this["api"].dns_name
    zone_id                = aws_lb.this["api"].zone_id
    evaluate_target_health = false
  }
}
resource "aws_vpc_security_group_ingress_rule" "alb_from_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "The website reads the API"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_lb_target_group" "web" {
  name                 = "${local.prefix}-web"
  vpc_id               = aws_vpc.this.id
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  health_check {
    path                = "/healthz"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}
resource "aws_lb_listener_rule" "web_theme" {
  listener_arn = aws_lb_listener.this["api"].arn
  priority     = 5
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this["api-public"].arn
  }
  condition {
    host_header {
      values = [var.web_host]
    }
  }
  condition {
    path_pattern {
      values = ["/theme/*"]
    }
  }
}
resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.this["api"].arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
  condition {
    host_header {
      values = [var.web_host]
    }
  }
}

# ---- CloudFront ----
# Cookies and tracking parameters make no new copy of a page: nothing in it depends on them.
resource "aws_cloudfront_cache_policy" "web" {
  name        = "${local.prefix}-web"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 31536000
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["cursor", "v"]
      }
    }
  }
}
resource "aws_cloudfront_origin_request_policy" "web" {
  name = "${local.prefix}-web"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Host"]
    }
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}
resource "aws_cloudfront_function" "www" {
  name    = "${local.prefix}-www"
  runtime = "cloudfront-js-2.0"
  comment = "One address: www goes to the site, for good"
  publish = true
  code    = <<-JS
    function handler(event) {
      var request = event.request;
      if (request.headers.host.value === "${var.web_host}") return request;
      return {
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: { location: { value: "https://${var.web_host}" + request.uri } },
      };
    }
  JS
}
resource "aws_cloudfront_distribution" "web" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2and3"
  aliases         = [var.web_host, "www.${var.web_host}"]
  price_class     = "PriceClass_All"
  web_acl_id      = aws_wafv2_web_acl.this["web"].arn
  origin {
    origin_id   = "web"
    domain_name = aws_lb.this["api"].dns_name
    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.this["api"].id
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
  }
  default_cache_behavior {
    target_origin_id         = "web"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = aws_cloudfront_cache_policy.web.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.web.id
    compress                 = true
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.www.arn
    }
  }
  # The newsroom's signed order. Never cached, and the only thing that may be posted.
  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = "web"
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.this["off"].id
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
}
resource "aws_route53_record" "web" {
  for_each = { for pair in setproduct([var.web_host, "www.${var.web_host}"], ["A", "AAAA"]) : "${pair[0]}-${pair[1]}" => { name = pair[0], type = pair[1] } }
  zone_id  = var.zone_id
  name     = each.value.name
  type     = each.value.type
  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = false
  }
}
