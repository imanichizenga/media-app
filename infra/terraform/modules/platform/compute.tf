resource "aws_ecr_repository" "this" {
  for_each             = toset(["api", "admin", "pgbouncer"])
  name                 = "${local.prefix}/${each.key}"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.data.arn
  }
}
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name
  policy = jsonencode({ rules = [{
    rulePriority = 1, description = "Keep 50 images", action = { type = "expire" }
    selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 50 }
  }] })
}
resource "aws_ecs_cluster" "this" {
  name = local.prefix
  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]
}
resource "aws_cloudwatch_log_group" "app" {
  for_each          = local.definitions
  name              = "/${local.prefix}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.data.arn
}

# ---- IAM: one execution role, and one task role per trust level ----
data "aws_iam_policy_document" "ecs" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account]
    }
  }
}
resource "aws_iam_role" "execution" {
  for_each           = toset(["runtime", "migrate"])
  name               = "${local.prefix}-exec-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.ecs.json
}
resource "aws_iam_role_policy_attachment" "execution" {
  for_each   = aws_iam_role.execution
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy" "execution" {
  for_each = aws_iam_role.execution
  role     = each.value.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow", Action = "secretsmanager:GetSecretValue"
        # Only the migration task can read the schema owner's credentials.
        Resource = [for n, s in aws_secretsmanager_secret.this : s.arn if each.key == "migrate" || n != "OWNER_DATABASE_URL"]
      },
      { Effect = "Allow", Action = "kms:Decrypt", Resource = aws_kms_key.data.arn },
    ]
  })
}
resource "aws_iam_role" "task" {
  for_each           = toset(["public", "admin", "realtime", "worker", "web", "migrate"])
  name               = "${local.prefix}-task-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.ecs.json
}
locals {
  policy_kms_decrypt = { Effect = "Allow", Action = ["kms:Decrypt"], Resource = aws_kms_key.app.arn }
  policy_kms_encrypt = { Effect = "Allow", Action = ["kms:GenerateDataKey"], Resource = aws_kms_key.app.arn }
  policy_media = [
    { Effect = "Allow", Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"], Resource = "${aws_s3_bucket.this["media"].arn}/*" },
    { Effect = "Allow", Action = ["s3:GetBucketPublicAccessBlock", "s3:ListBucket"], Resource = aws_s3_bucket.this["media"].arn },
    { Effect = "Allow", Action = ["cloudfront:GetDistributionConfig"], Resource = aws_cloudfront_distribution.media.arn },
  ]
  policy_audit = [
    # No delete and no retention bypass: the anchor can only ever be added to. DeleteObjectVersion stays denied.
    { Effect = "Allow", Action = ["s3:PutObject", "s3:PutObjectRetention", "s3:GetObject", "s3:GetObjectVersion"], Resource = "${aws_s3_bucket.this["audit"].arn}/*" },
    { Effect = "Allow", Action = ["s3:ListBucketVersions", "s3:GetBucketObjectLockConfiguration"], Resource = aws_s3_bucket.this["audit"].arn },
  ]
  policy_mail = [{ Effect = "Allow", Action = ["ses:SendEmail", "ses:GetAccount", "ses:GetEmailIdentity"], Resource = "*" }]
  policy_waf  = [{ Effect = "Allow", Action = ["wafv2:GetIPSet", "wafv2:UpdateIPSet"], Resource = [for s in aws_wafv2_ip_set.admin : s.arn] }]
  policy_metrics = [{
    Effect    = "Allow", Action = ["cloudwatch:PutMetricData"], Resource = "*"
    Condition = { StringEquals = { "cloudwatch:namespace" = local.prefix } }
  }]
  task_policies = {
    public = [local.policy_kms_decrypt]
    admin  = concat([local.policy_kms_decrypt, local.policy_kms_encrypt], local.policy_mail)
    worker = concat([local.policy_kms_decrypt], local.policy_media, local.policy_audit, local.policy_mail, local.policy_waf, local.policy_metrics)
  }
}
resource "aws_iam_role_policy" "task" {
  for_each = local.task_policies
  role     = aws_iam_role.task[each.key].id
  policy   = jsonencode({ Version = "2012-10-17", Statement = each.value })
}

# ---- task definitions ----
locals {
  bootstrap_env = {
    ENVIRONMENT            = var.environment
    DJANGO_SETTINGS_MODULE = "config.settings.production"
    ALLOWED_HOSTS          = "${var.api_host},${var.admin_host},localhost"
    ADMIN_ORIGIN           = "https://${var.admin_host}"
    WEBAUTHN_RP_ID         = var.admin_host
    KMS_KEY_ARN            = aws_kms_key.app.arn
    AWS_REGION             = local.region
    REDIS_CLUSTER          = "true"
    TRUSTED_PROXY_HOPS     = "2"       # CloudFront, then the load balancer
    DATABASE_SSLMODE       = "disable" # loopback to PgBouncer, which uses verify-full to RDS
    API_SURFACE            = "public"
    METRICS_NAMESPACE      = local.prefix
  }
  runtime_secrets = ["DJANGO_SECRET_KEY", "ORIGIN_VERIFY_SECRET", "DATABASE_URL", "REDIS_URL", "BROKER_URL"]
  uvicorn         = ["gunicorn", "config.asgi:application", "-k", "uvicorn_worker.UvicornWorker", "-b", "0.0.0.0:8000", "--access-logfile", "-"]
  # Staff sockets (ADR-0020). Pings keep idle sockets inside the load balancer's 60-second timeout.
  sockets = ["uvicorn", "config.asgi_realtime:application", "--host", "0.0.0.0", "--port", "8000", "--lifespan", "off", "--ws-max-size", "4096", "--ws-ping-interval", "20", "--no-server-header", "--timeout-graceful-shutdown", "30"]
  celery  = ["celery", "-A", "config"]
  # "ops" carries the queue measurement itself. Both services consume it, so a backlog cannot hide itself (ADR-0021).
  worker_queues = { worker-critical = ["critical"], worker-default = ["default", "sync"] }
  definitions = {
    api-public      = { image = "api", role = "public", port = 8000, env = { API_SURFACE = "public" }, command = local.uvicorn, tg = "api-public" }
    api-admin       = { image = "api", role = "admin", port = 8000, env = { API_SURFACE = "admin" }, command = local.uvicorn, tg = "api-admin" }
    ws-admin        = { image = "api", role = "realtime", port = 8000, env = { API_SURFACE = "realtime" }, command = local.sockets, tg = "ws-admin" }
    worker-critical = { image = "api", role = "worker", port = 0, env = {}, command = concat(local.celery, ["worker", "-Q", join(",", concat(["ops"], local.worker_queues["worker-critical"])), "-c", "4", "-l", "INFO"]), tg = null }
    worker-default  = { image = "api", role = "worker", port = 0, env = {}, command = concat(local.celery, ["worker", "-Q", join(",", concat(["ops"], local.worker_queues["worker-default"])), "-c", "4", "-l", "INFO"]), tg = null }
    beat            = { image = "api", role = "worker", port = 0, env = {}, command = concat(local.celery, ["beat", "-l", "INFO", "-s", "/tmp/celerybeat"]), tg = null }
    admin-web       = { image = "admin", role = "web", port = 3001, env = {}, command = ["apps/admin/server.js"], tg = "admin-web" }
    migrate         = { image = "api", role = "migrate", port = 0, env = { APP_DB_USER = "news_app", DATABASE_SSLMODE = "verify-full" }, command = ["python", "manage.py", "release"], tg = null }
  }
  deployed = { for k, d in local.definitions : k => d if k != "migrate" }
}
resource "aws_ecs_task_definition" "this" {
  for_each                 = local.definitions
  family                   = "${local.prefix}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = try(var.services[each.key].cpu, 512)
  memory                   = try(var.services[each.key].memory, 1024)
  execution_role_arn       = aws_iam_role.execution[each.key == "migrate" ? "migrate" : "runtime"].arn
  task_role_arn            = aws_iam_role.task[each.value.role].arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  volume {
    name = "tmp"
  }
  container_definitions = jsonencode(concat(
    [{
      name                   = "app"
      image                  = "${aws_ecr_repository.this[each.value.image].repository_url}:${var.image_tag}"
      essential              = true
      command                = each.value.command
      readonlyRootFilesystem = true
      linuxParameters        = { initProcessEnabled = true, capabilities = { drop = ["ALL"] } }
      mountPoints            = [{ sourceVolume = "tmp", containerPath = "/tmp" }]
      portMappings           = each.value.port > 0 ? [{ containerPort = each.value.port, protocol = "tcp" }] : []
      environment = each.value.image == "admin" ? [
        { name = "PORT", value = "3001" }, { name = "HOSTNAME", value = "0.0.0.0" }, { name = "SENTRY_DSN", value = var.sentry_browser_dsn }
      ] : [for k, v in merge(local.bootstrap_env, each.value.env) : { name = k, value = v }]
      secrets = each.value.image == "admin" ? [] : each.key == "migrate" ? concat(
        [for n in ["DJANGO_SECRET_KEY", "REDIS_URL", "BROKER_URL", "APP_DB_PASSWORD"] : { name = n, valueFrom = aws_secretsmanager_secret.this[n].arn }],
        [{ name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.this["OWNER_DATABASE_URL"].arn }],
      ) : [for n in local.runtime_secrets : { name = n, valueFrom = aws_secretsmanager_secret.this[n].arn }]
      dependsOn        = each.value.image == "api" && each.key != "migrate" ? [{ containerName = "pgbouncer", condition = "HEALTHY" }] : []
      stopTimeout      = 60
      logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.app[each.key].name, "awslogs-region" = local.region, "awslogs-stream-prefix" = "app" } }
    }],
    each.value.image == "api" && each.key != "migrate" ? [{
      name                   = "pgbouncer"
      image                  = "${aws_ecr_repository.this["pgbouncer"].repository_url}:${var.image_tag}"
      essential              = true
      readonlyRootFilesystem = true
      linuxParameters        = { capabilities = { drop = ["ALL"] } }
      mountPoints            = [{ sourceVolume = "tmp", containerPath = "/tmp" }]
      environment            = [{ name = "DB_HOST", value = aws_db_instance.primary.address }, { name = "DB_USER", value = "news_app" }, { name = "DB_NAME", value = "news" }]
      secrets                = [{ name = "DB_PASSWORD", valueFrom = aws_secretsmanager_secret.this["APP_DB_PASSWORD"].arn }]
      healthCheck            = { command = ["CMD-SHELL", "nc -z 127.0.0.1 6432"], interval = 5, timeout = 3, retries = 5, startPeriod = 5 }
      portMappings           = []
      logConfiguration       = { logDriver = "awslogs", options = { "awslogs-group" = aws_cloudwatch_log_group.app[each.key].name, "awslogs-region" = local.region, "awslogs-stream-prefix" = "pgbouncer" } }
    }] : [],
  ))
}
resource "aws_ecs_service" "this" {
  for_each                           = local.deployed
  name                               = each.key
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this[each.key].arn
  desired_count                      = var.services[each.key].min
  launch_type                        = "FARGATE"
  propagate_tags                     = "SERVICE"
  availability_zone_rebalancing      = each.key == "beat" ? "DISABLED" : "ENABLED"
  deployment_minimum_healthy_percent = each.key == "beat" ? 0 : 100
  deployment_maximum_percent         = each.key == "beat" ? 100 : 200 # beat must never run twice
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets         = [for s in aws_subnet.app : s.id]
    security_groups = [aws_security_group.app.id]
  }
  dynamic "load_balancer" {
    for_each = each.value.tg == null ? [] : [each.value.tg]
    content {
      target_group_arn = aws_lb_target_group.this[load_balancer.value].arn
      container_name   = "app"
      container_port   = each.value.port
    }
  }
  depends_on = [aws_lb_listener.this, aws_lb_listener_rule.admin_api, aws_lb_listener_rule.admin_ws]
  lifecycle {
    ignore_changes = [task_definition, desired_count] # owned by CI/CD and autoscaling
  }
}
resource "aws_appautoscaling_target" "this" {
  for_each           = { for k, d in local.deployed : k => d if k != "beat" }
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.services[each.key].min
  max_capacity       = var.services[each.key].max
}
resource "aws_appautoscaling_policy" "cpu" {
  for_each           = aws_appautoscaling_target.this
  name               = "cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = each.value.service_namespace
  resource_id        = each.value.resource_id
  scalable_dimension = each.value.scalable_dimension
  target_tracking_scaling_policy_configuration {
    target_value       = 55
    scale_in_cooldown  = 120
    scale_out_cooldown = 30
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
resource "aws_appautoscaling_policy" "requests" {
  # A socket is one request for hours, so request counts say nothing about ws-admin: it scales on CPU.
  for_each           = { for k, d in local.deployed : k => d if d.tg != null && k != "ws-admin" }
  name               = "requests"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  target_tracking_scaling_policy_configuration {
    target_value       = 600
    scale_in_cooldown  = 120
    scale_out_cooldown = 30
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.this[each.key == "api-public" ? "api" : "admin"].arn_suffix}/${aws_lb_target_group.this[each.value.tg].arn_suffix}"
    }
  }
}
# Waiting messages per running task. Scale-in happens only when the CPU policy agrees.
resource "aws_appautoscaling_policy" "backlog" {
  for_each           = local.worker_queues
  name               = "backlog"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  target_tracking_scaling_policy_configuration {
    target_value       = var.backlog_per_task[each.key]
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
    customized_metric_specification {
      dynamic "metrics" {
        for_each = each.value
        content {
          id          = "q${metrics.key}"
          return_data = false
          metric_stat {
            stat = "Maximum"
            metric {
              namespace   = local.prefix
              metric_name = "QueueDepth"
              dimensions {
                name  = "Queue"
                value = metrics.value
              }
            }
          }
        }
      }
      metrics {
        id          = "tasks"
        return_data = false
        metric_stat {
          stat = "Average"
          metric {
            namespace   = "ECS/ContainerInsights"
            metric_name = "RunningTaskCount"
            dimensions {
              name  = "ClusterName"
              value = aws_ecs_cluster.this.name
            }
            dimensions {
              name  = "ServiceName"
              value = each.key
            }
          }
        }
      }
      metrics {
        id          = "backlog"
        label       = "Waiting messages per task"
        expression  = "(${join(" + ", [for i, _ in each.value : "q${i}"])}) / tasks"
        return_data = true
      }
    }
  }
}
