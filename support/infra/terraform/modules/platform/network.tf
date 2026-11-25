data "aws_availability_zones" "this" {
  state = "available"
}
data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  prefix  = "${var.name}-${var.environment}"
  account = data.aws_caller_identity.this.account_id
  region  = data.aws_region.this.region
  azs     = slice(data.aws_availability_zones.this.names, 0, var.az_count)
  nat_azs = var.nat_per_az ? local.azs : slice(local.azs, 0, 1)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = local.prefix }
}
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = local.prefix }
}
resource "aws_subnet" "public" {
  for_each          = { for i, az in local.azs : az => i }
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, each.value)
  tags              = { Name = "${local.prefix}-public-${each.key}" }
}
resource "aws_subnet" "app" {
  for_each          = { for i, az in local.azs : az => i }
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value + 4)
  tags              = { Name = "${local.prefix}-app-${each.key}" }
}
resource "aws_subnet" "data" {
  for_each          = { for i, az in local.azs : az => i }
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 6, each.value + 8)
  tags              = { Name = "${local.prefix}-data-${each.key}" }
}
resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)
  domain   = "vpc"
}
resource "aws_nat_gateway" "this" {
  for_each      = toset(local.nat_azs)
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.this]
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "app" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.nat_per_az ? each.key : local.nat_azs[0]].id
  }
}
resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}
# Data subnets have no route to the internet in either direction.
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id
}
resource "aws_route_table_association" "data" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data.id
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.this.id
  service_name    = "com.amazonaws.${local.region}.s3"
  route_table_ids = [for t in aws_route_table.app : t.id]
}
resource "aws_flow_log" "this" {
  vpc_id               = aws_vpc.this.id
  traffic_type         = "REJECT"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow.arn
  iam_role_arn         = aws_iam_role.flow.arn
}
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/${local.prefix}/vpc-flow"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.data.arn
}
resource "aws_iam_role" "flow" {
  name = "${local.prefix}-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow", Action = "sts:AssumeRole", Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Condition = { StringEquals = { "aws:SourceAccount" = local.account } }
    }]
  })
}
resource "aws_iam_role_policy" "flow" {
  role = aws_iam_role.flow.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      Resource = "${aws_cloudwatch_log_group.flow.arn}:*"
    }]
  })
}

# ---- security groups ----
resource "aws_security_group" "alb" {
  name        = "${local.prefix}-alb"
  description = "Internal load balancers, reachable only through CloudFront VPC origins"
  vpc_id      = aws_vpc.this.id
}
resource "aws_security_group" "app" {
  name        = "${local.prefix}-app"
  description = "ECS tasks"
  vpc_id      = aws_vpc.this.id
}
resource "aws_security_group" "data" {
  name        = "${local.prefix}-data"
  description = "PostgreSQL and Redis"
  vpc_id      = aws_vpc.this.id
}
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}
resource "aws_vpc_security_group_ingress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  description       = "CloudFront only"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "alb" {
  for_each                     = toset(["3000", "3001", "8000"])
  security_group_id            = aws_security_group.alb.id
  description                  = "To tasks"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each                     = toset(["3000", "3001", "8000"])
  security_group_id            = aws_security_group.app.id
  description                  = "From load balancers"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "AWS APIs and integrations"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
resource "aws_vpc_security_group_egress_rule" "app_data" {
  for_each                     = toset(["5432", "6379"])
  security_group_id            = aws_security_group.app.id
  description                  = "To data stores"
  referenced_security_group_id = aws_security_group.data.id
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  ip_protocol                  = "tcp"
}
resource "aws_vpc_security_group_ingress_rule" "data" {
  for_each                     = toset(["5432", "6379"])
  security_group_id            = aws_security_group.data.id
  description                  = "From tasks only"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = tonumber(each.key)
  to_port                      = tonumber(each.key)
  ip_protocol                  = "tcp"
}
