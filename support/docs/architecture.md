# Architecture (M1)

```
Browser ─ CloudFront+WAF ─ VPC origin ─ internal ALB ─┬ /api/v1/* → api-admin  ─┐
 (admin host)                                         ├ /ws/* → ws-admin (Channels)    │
                                                      └ everything else → admin-web (Next.js)
Clients ─ CloudFront+WAF ─ VPC origin ─ internal ALB ── api-public ─────────────┤
Media   ─ CloudFront+WAF ─ OAC ─ S3 media/ (private)                            │
Uploads ─ presigned parts ─ S3 originals/ ─ GuardDuty ─ worker-media ─ MediaConvert
                                   PgBouncer sidecars → RDS PostgreSQL 17 ◄─────┤
                                   ElastiCache: cache (cluster) + broker ◄──────┤
                                   Celery: critical, default, media, beat ─────────────┘ → S3, SES, WAF, KMS
```

## Backend modules (`backend/newsplatform`)
| Module | Responsibility |
|---|---|
| `common` | Context, errors, logging with redaction, rate limits, SSRF-safe HTTP, encryption, replica routing |
| `accounts` | Identity |
| `rbac` | Permission catalogue, roles, scoped grants |
| `audit` | Hash chain, verification, anchors |
| `approvals` | Four-eyes requests |
| `site_config` | Typed, versioned settings |
| `integrations` | Provider contract, versions, tests, call log |
| `realtime` | Staff sockets: tickets, topics, change signals |
| `taxonomy` | Categories (three levels), tags, stories, regions |
| `content` | Posts, workflow, revisions, publications, public read API, demo content |
| `media` | Uploads, scanning, image variants, adaptive video, YouTube |
| `engagement` | Engagement policy and its resolution (enforcement in M4) |
| `seo` | Addresses, redirects, purge and revalidation |
| `ops` | Queue measurements |
| `staff_security` | Sign-in, MFA, sessions, invitations |

## Shared packages
`content-schema` (article bodies, ADR-0027), `ui` (primitives and the article renderer, used by admin and web), `design-tokens`, `api-client`, `api-client-dart`.

Views validate and delegate. Services write, inside transactions, with audit. Selectors read.

## Adding an integration
Subclass `Provider` with a Pydantic `ProviderConfig`, implement `test()`, decorate with `@register_provider`. The admin form, encryption, versioning, test history and approvals come with it.
