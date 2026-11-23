# 0015. Database access

Status: accepted, 2026-11-23

## Context
Pooling, replicas, least privilege.

## Decision
PgBouncer sidecar in transaction mode, verify-full TLS to RDS. Migrations run as the owner; the app runs as `news_app`, which cannot alter audit history. Replica reads are opt-in with `use_replica()`.

## Alternatives
RDS Proxy (pins sessions); automatic read routing.

## Consequences
No server-side cursors or prepared statements. Stale reads are always a visible choice.
