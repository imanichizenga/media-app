# Architecture (M0)

```
Browser ─ CloudFront+WAF ─ VPC origin ─ internal ALB ─┬ /api/v1/* → api-admin  ─┐
 (admin host)                                         └ everything else → admin-web (Next.js)
Clients ─ CloudFront+WAF ─ VPC origin ─ internal ALB ── api-public ─────────────┤
Media   ─ CloudFront+WAF ─ OAC ─ S3 (private)                                   │
                                   PgBouncer sidecars → RDS PostgreSQL 17 ◄─────┤
                                   ElastiCache: cache (cluster) + broker ◄──────┤
                                   Celery: critical, default, beat ─────────────┘ → S3, SES, WAF, KMS
```

## Backend modules (`apps/api/newsplatform`)
| Module | Responsibility |
|---|---|
| `common` | Context, errors, logging with redaction, rate limits, SSRF-safe HTTP, encryption, replica routing |
| `accounts` | Identity |
| `rbac` | Permission catalogue, roles, scoped grants |
| `audit` | Hash chain, verification, anchors |
| `approvals` | Four-eyes requests |
| `site_config` | Typed, versioned settings |
| `integrations` | Provider contract, versions, tests, call log |
| `staff_security` | Sign-in, MFA, sessions, invitations |

Views validate and delegate. Services write, inside transactions, with audit. Selectors read.

## Adding an integration
Subclass `Provider` with a Pydantic `ProviderConfig`, implement `test()`, decorate with `@register_provider`. The admin form, encryption, versioning, test history and approvals come with it.
