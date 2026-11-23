resource "aws_sns_topic" "alarms" {
  name              = "${local.prefix}-alarms"
  kms_master_key_id = aws_kms_key.data.arn
}
resource "aws_sns_topic_subscription" "email" {
  for_each  = var.alarm_emails
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}
resource "aws_cloudwatch_log_metric_filter" "events" {
  for_each = {
    for pair in setproduct(["worker-default", "api-admin"], ["audit_chain_broken", "session_hijack_suspected", "password_breach_check_unavailable", "unhandled_error"]) :
    "${pair[0]}-${pair[1]}" => { group = pair[0], event = pair[1] }
  }
  name           = each.value.event
  log_group_name = aws_cloudwatch_log_group.app[each.value.group].name
  pattern        = "{ $.event = \"${each.value.event}\" }"
  metric_transformation {
    namespace = local.prefix
    name      = each.value.event
    value     = "1"
  }
}
locals {
  alarms = merge(
    {
      audit-chain-broken = { ns = local.prefix, metric = "audit_chain_broken", dims = {}, stat = "Sum", op = ">=", threshold = 1, period = 60, runs = 1 }
      unhandled-errors   = { ns = local.prefix, metric = "unhandled_error", dims = {}, stat = "Sum", op = ">=", threshold = 20, period = 300, runs = 1 }
      db-cpu             = { ns = "AWS/RDS", metric = "CPUUtilization", dims = { DBInstanceIdentifier = aws_db_instance.primary.identifier }, stat = "Average", op = ">=", threshold = 80, period = 300, runs = 3 }
      db-storage         = { ns = "AWS/RDS", metric = "FreeStorageSpace", dims = { DBInstanceIdentifier = aws_db_instance.primary.identifier }, stat = "Minimum", op = "<=", threshold = 10737418240, period = 300, runs = 2 }
    },
    { for k, lb in aws_lb.this : "${k}-5xx" => { ns = "AWS/ApplicationELB", metric = "HTTPCode_Target_5XX_Count", dims = { LoadBalancer = lb.arn_suffix }, stat = "Sum", op = ">=", threshold = 25, period = 60, runs = 3 } },
    { for k, lb in aws_lb.this : "${k}-latency" => { ns = "AWS/ApplicationELB", metric = "TargetResponseTime", dims = { LoadBalancer = lb.arn_suffix }, stat = "p95", op = ">=", threshold = 0.5, period = 60, runs = 5 } },
    {
      for queue, threshold in { critical = 200, default = 5000, sync = 1000 } :
      "queue-${queue}" => { ns = local.prefix, metric = "QueueDepth", dims = { Queue = queue }, stat = "Maximum", op = ">=", threshold = threshold, period = 60, runs = 5, runbook = "queue-backlog" }
    },
    # Without the measurement nothing scales: silence is the alarm.
    { queue-metric-missing = { ns = local.prefix, metric = "QueueDepth", dims = { Queue = "critical" }, stat = "SampleCount", op = "<=", threshold = 0, period = 60, runs = 5, runbook = "queue-backlog", missing = "breaching" } },
  )
}
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each            = local.alarms
  alarm_name          = "${local.prefix}-${each.key}"
  alarm_description   = "See docs/runbooks/${try(each.value.runbook, each.key)}.md"
  namespace           = each.value.ns
  metric_name         = each.value.metric
  dimensions          = each.value.dims
  statistic           = startswith(each.value.stat, "p") ? null : each.value.stat
  extended_statistic  = startswith(each.value.stat, "p") ? each.value.stat : null
  comparison_operator = each.value.op == ">=" ? "GreaterThanOrEqualToThreshold" : "LessThanOrEqualToThreshold"
  threshold           = each.value.threshold
  period              = each.value.period
  evaluation_periods  = each.value.runs
  treat_missing_data  = try(each.value.missing, "notBreaching")
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
}
