# Generated credentials are ephemeral and written with write-only arguments: they never enter Terraform state.
ephemeral "random_password" "this" {
  for_each = toset(["owner", "app", "cache", "broker", "django", "origin", "web", "revalidate"])
  length   = 64
  special  = false
}

resource "aws_db_subnet_group" "this" {
  name       = local.prefix
  subnet_ids = [for s in aws_subnet.data : s.id]
}
resource "aws_db_parameter_group" "this" {
  name   = "${local.prefix}-pg17"
  family = "postgres17"
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }
  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "30000"
  }
}
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.prefix}-rds-monitoring"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "monitoring.rds.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
resource "aws_db_instance" "primary" {
  identifier                          = local.prefix
  engine                              = "postgres"
  engine_version                      = "17"
  instance_class                      = var.db_instance_class
  allocated_storage                   = var.db_allocated_gb
  max_allocated_storage               = var.db_allocated_gb * 5
  storage_type                        = "gp3"
  storage_encrypted                   = true
  kms_key_id                          = aws_kms_key.data.arn
  db_name                             = "news"
  username                            = "news_owner"
  password_wo                         = ephemeral.random_password.this["owner"].result
  password_wo_version                 = var.secrets_version
  multi_az                            = var.db_multi_az
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.data.id]
  parameter_group_name                = aws_db_parameter_group.this.name
  publicly_accessible                 = false
  backup_retention_period             = 14
  backup_window                       = "00:00-01:00"
  maintenance_window                  = "sun:01:30-sun:02:30"
  copy_tags_to_snapshot               = true
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = !var.deletion_protection
  final_snapshot_identifier           = "${local.prefix}-final"
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = aws_kms_key.data.arn
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
}
resource "aws_db_instance" "replica" {
  count                           = var.db_replicas
  identifier                      = "${local.prefix}-replica-${count.index + 1}"
  replicate_source_db             = aws_db_instance.primary.identifier
  instance_class                  = var.db_instance_class
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.data.arn
  vpc_security_group_ids          = [aws_security_group.data.id]
  parameter_group_name            = aws_db_parameter_group.this.name
  publicly_accessible             = false
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.data.arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = true
  copy_tags_to_snapshot           = true
}

resource "aws_elasticache_subnet_group" "this" {
  name       = local.prefix
  subnet_ids = [for s in aws_subnet.data : s.id]
}
# Celery's Redis transport does not support cluster mode, so the broker is a separate, non-evicting group.
resource "aws_elasticache_parameter_group" "this" {
  for_each = {
    cache  = [["cluster-enabled", "yes"], ["maxmemory-policy", "volatile-lru"]]
    broker = [["cluster-enabled", "no"], ["maxmemory-policy", "noeviction"]]
    # The website's answers and single-use numbers: apart from the API's, so neither can read or evict the other's.
    web = [["cluster-enabled", "no"], ["maxmemory-policy", "volatile-lru"]]
  }
  name   = "${local.prefix}-${each.key}"
  family = "redis7"
  dynamic "parameter" {
    for_each = each.value
    content {
      name  = parameter.value[0]
      value = parameter.value[1]
    }
  }
}
resource "aws_elasticache_replication_group" "this" {
  for_each                   = { cache = var.cache_shards, broker = 1, web = 1 }
  replication_group_id       = "${local.prefix}-${each.key}"
  description                = "${local.prefix} ${each.key}"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = var.cache_node_type
  parameter_group_name       = aws_elasticache_parameter_group.this[each.key].name
  num_node_groups            = each.value
  replicas_per_node_group    = var.cache_replicas
  automatic_failover_enabled = var.cache_replicas > 0
  multi_az_enabled           = var.cache_replicas > 0
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.data.id]
  at_rest_encryption_enabled = true
  kms_key_id                 = aws_kms_key.data.arn
  transit_encryption_enabled = true
  auth_token_wo              = ephemeral.random_password.this[each.key].result
  auth_token_wo_version      = var.secrets_version
  snapshot_retention_limit   = each.key == "broker" ? 3 : 0
  apply_immediately          = var.environment != "prod"
}

locals {
  redis_host = {
    cache  = aws_elasticache_replication_group.this["cache"].configuration_endpoint_address
    broker = aws_elasticache_replication_group.this["broker"].primary_endpoint_address
    web    = aws_elasticache_replication_group.this["web"].primary_endpoint_address
  }
  # Values the app reads through PgBouncer on localhost, so DATABASE_URL points at the sidecar.
  secret_values = {
    DJANGO_SECRET_KEY    = ephemeral.random_password.this["django"].result
    ORIGIN_VERIFY_SECRET = ephemeral.random_password.this["origin"].result
    APP_DB_PASSWORD      = ephemeral.random_password.this["app"].result
    DATABASE_URL         = "postgresql://news_app:${ephemeral.random_password.this["app"].result}@127.0.0.1:6432/news"
    OWNER_DATABASE_URL   = "postgresql://news_owner:${ephemeral.random_password.this["owner"].result}@${aws_db_instance.primary.address}:5432/news"
    REDIS_URL            = "rediss://:${ephemeral.random_password.this["cache"].result}@${local.redis_host.cache}:6379/0"
    BROKER_URL           = "rediss://:${ephemeral.random_password.this["broker"].result}@${local.redis_host.broker}:6379/0?ssl_cert_reqs=required"
    WEB_REDIS_URL        = "rediss://:${ephemeral.random_password.this["web"].result}@${local.redis_host.web}:6379/0"
    # Also entered, once, in Admin → Integrations → Website and CDN.
    REVALIDATE_SECRET = ephemeral.random_password.this["revalidate"].result
  }
  secret_names = toset(["DJANGO_SECRET_KEY", "ORIGIN_VERIFY_SECRET", "APP_DB_PASSWORD", "DATABASE_URL", "OWNER_DATABASE_URL", "REDIS_URL", "BROKER_URL", "WEB_REDIS_URL", "REVALIDATE_SECRET"])
}
resource "aws_secretsmanager_secret" "this" {
  for_each                = local.secret_names
  name                    = "${local.prefix}/${each.key}"
  kms_key_id              = aws_kms_key.data.arn
  recovery_window_in_days = var.deletion_protection ? 30 : 7
}
resource "aws_secretsmanager_secret_version" "this" {
  for_each                 = local.secret_names
  secret_id                = aws_secretsmanager_secret.this[each.key].id
  secret_string_wo         = local.secret_values[each.key]
  secret_string_wo_version = var.secrets_version
}
