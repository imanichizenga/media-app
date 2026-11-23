# 0016. CI/CD and rollback

Status: accepted, 2026-11-23

## Context
Safe, repeatable releases.

## Decision
GitHub OIDC, no stored keys. One required check. Images are immutable, scanned, with SBOM and provenance. Release task → roll services (circuit breaker) → smoke test → automatic return to the previous revisions. Migrations are expand/contract.

## Alternatives
Blue/green with CodeDeploy.

## Consequences
The deploy role cannot change infrastructure, IAM or data. The old code must run against the new schema.
