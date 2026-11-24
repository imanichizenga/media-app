# 0011. Bootstrap environment variables

Status: accepted, 2026-11-23

## Context
The brief limits environment variables.

## Decision
Bootstrap only: database, Redis, broker, Django key, KMS ARN, environment, hosts, admin origin, RP ID, proxy hops, origin secret. Exception: `SENTRY_DSN`, `METRICS_NAMESPACE` and `OTEL_*`, which must work when the database is down.

## Alternatives
Telemetry settings in the DB.

## Consequences
BROKER_URL is separate from REDIS_URL (ADR-0014). Sentry SDK 3 collects most data by default, so collection is explicitly restricted.
