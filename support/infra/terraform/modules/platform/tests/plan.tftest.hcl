mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["af-south-1a", "af-south-1b", "af-south-1c"] }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_region" {
    defaults = { region = "af-south-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}
mock_provider "aws" {
  alias = "us_east_1"
}
variables {
  environment       = "prod"
  zone_id           = "Z1"
  api_host          = "api.example.com"
  admin_host        = "admin.example.com"
  media_host        = "media.example.com"
  web_host          = "example.com"
  nat_per_az        = true
  db_instance_class = "db.r8g.xlarge"
  db_allocated_gb   = 200
  db_multi_az       = true
  db_replicas       = 1
  cache_node_type   = "cache.r7g.large"
  cache_shards      = 3
  services = {
    api-public      = { cpu = 1024, memory = 2048, min = 3, max = 60 }
    api-admin       = { cpu = 512, memory = 1024, min = 3, max = 4 }
    admin-web       = { cpu = 512, memory = 1024, min = 3, max = 4 }
    web             = { cpu = 1024, memory = 2048, min = 3, max = 40 }
    ws-admin        = { cpu = 256, memory = 1024, min = 2, max = 4 }
    worker-critical = { cpu = 512, memory = 1024, min = 3, max = 10 }
    worker-default  = { cpu = 512, memory = 1024, min = 3, max = 10 }
    worker-media    = { cpu = 2048, memory = 4096, min = 2, max = 20 }
    beat            = { cpu = 256, memory = 512, min = 1, max = 1 }
  }
}
run "storage_is_private" {
  command = plan
  assert {
    condition     = alltrue([for b in aws_s3_bucket_public_access_block.this : b.block_public_acls && b.block_public_policy && b.ignore_public_acls && b.restrict_public_buckets])
    error_message = "Every bucket needs all four Block Public Access settings."
  }
  assert {
    condition     = aws_s3_bucket.this["audit"].object_lock_enabled && aws_s3_bucket_object_lock_configuration.audit.rule[0].default_retention[0].mode == "COMPLIANCE"
    error_message = "The audit bucket must be WORM in COMPLIANCE mode."
  }
  assert {
    condition     = aws_cloudfront_origin_access_control.media.signing_behavior == "always"
    error_message = "OAC must sign every request."
  }
}
run "data_is_protected" {
  command = plan
  assert {
    condition     = aws_db_instance.primary.storage_encrypted && !aws_db_instance.primary.publicly_accessible && aws_db_instance.primary.multi_az && aws_db_instance.primary.deletion_protection && aws_db_instance.primary.backup_retention_period >= 14
    error_message = "The database must be encrypted, private, Multi-AZ, protected and backed up."
  }
  assert {
    condition     = alltrue([for g in aws_elasticache_replication_group.this : g.transit_encryption_enabled && g.at_rest_encryption_enabled])
    error_message = "Redis must be encrypted in transit and at rest."
  }
  assert {
    condition     = aws_elasticache_replication_group.this["broker"].num_node_groups == 1
    error_message = "Celery cannot use a cluster-mode broker."
  }
}
run "nothing_is_reachable_except_through_cloudfront" {
  command = plan
  assert {
    condition     = alltrue([for lb in aws_lb.this : lb.internal])
    error_message = "Load balancers must be internal."
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb.cidr_ipv4 == null
    error_message = "Load balancers accept CloudFront's prefix list only."
  }
  assert {
    condition     = !anytrue([for a in flatten([for s in aws_wafv2_ip_set.admin : s.addresses]) : endswith(a, "/0")])
    error_message = "AWS WAF rejects /0."
  }
}
run "beat_is_a_singleton" {
  command = plan
  assert {
    condition     = aws_ecs_service.this["beat"].desired_count == 1 && aws_ecs_service.this["beat"].deployment_maximum_percent == 100
    error_message = "Two schedulers would send everything twice."
  }
  assert {
    condition     = alltrue([for s in aws_ecs_service.this : s.deployment_circuit_breaker[0].enable && s.deployment_circuit_breaker[0].rollback])
    error_message = "Every service needs automatic rollback."
  }
}
run "workers_scale_on_backlog" {
  command = plan
  assert {
    condition     = toset(keys(aws_appautoscaling_policy.backlog)) == toset([for k, _ in aws_ecs_service.this : k if startswith(k, "worker-")])
    error_message = "Every worker service scales on its queues."
  }
  assert {
    condition = alltrue([for p in aws_appautoscaling_policy.backlog : length([
      for m in p.target_tracking_scaling_policy_configuration[0].customized_metric_specification[0].metrics : m if m.return_data
    ]) == 1])
    error_message = "Target tracking needs exactly one returned metric."
  }
  assert {
    condition     = alltrue([for k, d in local.definitions : strcontains(join(" ", d.command), "-Q ops,${join(",", local.worker_queues[k])} ") if startswith(k, "worker-")])
    error_message = "Every worker consumes the measurement queue, or a backlog hides itself."
  }
  assert {
    condition     = aws_cloudwatch_metric_alarm.this["queue-metric-missing"].treat_missing_data == "breaching"
    error_message = "A silent publisher must alarm."
  }
}
run "sockets_are_separate" {
  command = plan
  assert {
    condition     = one(one(aws_lb_listener_rule.admin_ws.condition).path_pattern).values == toset(["/ws/*"]) && aws_lb_listener_rule.admin_ws.priority < aws_lb_listener_rule.admin_api.priority
    error_message = "Sockets have their own service, matched first."
  }
  assert {
    condition     = !contains(keys(aws_iam_role_policy.task), "realtime")
    error_message = "The socket service needs no AWS permissions."
  }
  assert {
    condition     = !contains(keys(aws_appautoscaling_policy.requests), "ws-admin")
    error_message = "Request counts do not describe sockets."
  }
}
run "uploads_are_scanned_before_anything_opens_them" {
  command = plan
  assert {
    condition     = aws_guardduty_malware_protection_plan.media.actions[0].tagging[0].status == "ENABLED" && contains(one(one(aws_guardduty_malware_protection_plan.media.protected_resource).s3_bucket).object_prefixes, "originals/")
    error_message = "Every original is scanned and tagged with its verdict."
  }
  assert {
    condition     = toset([for s in data.aws_iam_policy_document.bucket["media"].statement : s.sid if s.effect == "Deny"]) == toset(["TlsOnly", "NoReadUnlessClean", "OnlyTheScannerGivesVerdicts"])
    error_message = "The bucket itself refuses unscanned originals and forged verdicts."
  }
  assert {
    condition     = one(aws_s3_bucket_cors_configuration.media.cors_rule).allowed_origins == toset(["https://admin.example.com"]) && one(aws_s3_bucket_cors_configuration.media.cors_rule).allowed_methods == toset(["PUT"])
    error_message = "Only the console may upload from a browser, and only with PUT."
  }
}
run "the_media_worker_is_confined" {
  command = plan
  assert {
    condition     = local.definitions["worker-media"].role == "media" && !anytrue([for a in flatten([for s in local.task_policies.media : s.Action]) : startswith(a, "ses:") || a == "kms:GenerateDataKey"])
    error_message = "The process that opens uploaded files can neither send mail nor encrypt secrets."
  }
  assert {
    condition     = !anytrue([for a in flatten([for s in local.task_policies.admin : s.Action]) : startswith(a, "s3:Get") || startswith(a, "s3:Delete")])
    error_message = "The console signs uploads. It does not read or delete media."
  }
}
run "the_website_is_kept_by_the_cdn_and_knows_no_reader" {
  command = plan
  assert {
    condition     = one(one(aws_cloudfront_cache_policy.web.parameters_in_cache_key_and_forwarded_to_origin).cookies_config).cookie_behavior == "none" && one(aws_cloudfront_origin_request_policy.web.cookies_config).cookie_behavior == "none"
    error_message = "No cookie may reach the website or split its cache."
  }
  assert {
    condition     = one(one(one(aws_cloudfront_cache_policy.web.parameters_in_cache_key_and_forwarded_to_origin).query_strings_config).query_strings).items == toset(["cursor", "v"])
    error_message = "Tracking parameters must not make new copies of a page."
  }
  assert {
    condition     = one(aws_cloudfront_distribution.web.default_cache_behavior).allowed_methods == toset(["GET", "HEAD"]) && one(aws_cloudfront_distribution.web.ordered_cache_behavior).path_pattern == "/api/*" && contains(one(aws_cloudfront_distribution.web.ordered_cache_behavior).allowed_methods, "POST")
    error_message = "Pages are read only; the signed order is never cached."
  }
  assert {
    condition     = aws_cloudfront_distribution.web.aliases == toset(["example.com", "www.example.com"]) && strcontains(aws_cloudfront_function.www.code, "statusCode: 301")
    error_message = "One address: www redirects."
  }
  assert {
    condition     = aws_lb_listener_rule.web_theme.priority < aws_lb_listener_rule.web.priority
    error_message = "The theme comes from the API, before the website answers for the rest."
  }
}
run "the_website_holds_no_key_but_its_own" {
  command = plan
  assert {
    condition     = local.definitions.web.role == "site" && !contains(keys(local.task_policies), "site")
    error_message = "The website needs no AWS permissions."
  }
  assert {
    condition     = length(setintersection(toset(local.web_secrets), toset(local.runtime_secrets))) == 0
    error_message = "The website shares no secret with the API."
  }
  assert {
    condition     = aws_elasticache_replication_group.this["web"].num_node_groups == 1 && aws_elasticache_replication_group.this["web"].transit_encryption_enabled
    error_message = "Its cache is its own, encrypted, and not a cluster (its client is not)."
  }
  assert {
    condition     = aws_route53_zone.internal.name == "api.example.com" && one(aws_route53_zone.internal.vpc) != null
    error_message = "The website reads the API inside the network, past no CDN."
  }
}
run "only_production_is_indexed" {
  command = plan
  variables {
    environment = "staging"
  }
  assert {
    condition     = local.web_env.SITE_CLOSED == "1"
    error_message = "Search engines must not see staging."
  }
}
