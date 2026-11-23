# 0014. AWS topology

Status: accepted, 2026-11-23

## Context
Millions of readers, private origins.

## Decision
af-south-1. CloudFront + WAF in front of internal load balancers through VPC origins, so nothing is publicly reachable. Admin also sits behind CloudFront, which supplies the viewer country. ECS Fargate (ARM). Two Redis groups: cluster-mode cache and a non-cluster broker, because Celery's transport does not support cluster mode. Generated passwords use ephemeral values and write-only arguments, so they are never in Terraform state. Admin web runs on ECS, not Vercel: the allowlist must cover it.

## Alternatives
Public ALBs; Vercel; EKS.

## Consequences
The admin allowlist is a CLOUDFRONT-scope WAF IP set (us-east-1), owned by the admin console. Accepted scanner findings are in `.trivyignore`.
