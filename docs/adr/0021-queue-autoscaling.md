# 0021. Worker autoscaling on queue depth

Status: accepted, 2026-11-23

## Context
CPU does not show waiting work: a worker blocked on a slow provider is idle while its queue grows.

## Decision
Celery Beat sends a measurement every minute. It writes the length of every queue to CloudWatch (`QueueDepth`, dimension `Queue`). ECS target tracking divides a service's queues by its running tasks (metric math) and keeps that at a target; CPU tracking stays beside it. The measurement has its own queue, `ops`, consumed by every worker service. Kombu's Redis transport serves queues in turn, so a backlog cannot delay its own measurement for longer than the tasks already running. It expires after 50 seconds. No data for 5 minutes is an alarm.

## Alternatives
Measuring on `critical` (a backlog would hide itself); a Lambda with VPC access; a Prometheus exporter; CloudWatch Embedded Metric Format (no synchronous failure to notice).

## Consequences
Scaling reacts in one to three minutes. Queues without a service yet (media, notifications, analytics) are measured already; their service adds itself to `worker_queues`.
