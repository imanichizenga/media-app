output "cluster" { value = aws_ecs_cluster.this.name }
output "repositories" { value = { for k, r in aws_ecr_repository.this : k => r.repository_url } }
output "app_subnets" { value = [for s in aws_subnet.app : s.id] }
output "app_security_group" { value = aws_security_group.app.id }
output "distributions" { value = { for k, d in aws_cloudfront_distribution.app : k => d.id } }
# The values to enter in the admin console's S3, audit-anchor and WAF forms.
output "console" {
  value = {
    region                = local.region
    media_bucket          = aws_s3_bucket.this["media"].id
    media_domain          = var.media_host
    media_distribution_id = aws_cloudfront_distribution.media.id
    mediaconvert_role_arn = aws_iam_role.mediaconvert.arn
    api_distribution_id   = aws_cloudfront_distribution.app["api"].id
    audit_bucket          = aws_s3_bucket.this["audit"].id
    waf_ip_sets           = { for k, s in aws_wafv2_ip_set.admin : k => { name = s.name, id = s.id } }
  }
}
