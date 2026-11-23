# Progress

| Milestone | Status |
|---|---|
| **M0 Foundation** | Code complete and verified locally. **Not accepted**: two of four acceptance checks need an AWS account. |
| M1 to M11 | Not started |

## M0 acceptance

| Criterion | Status | Evidence |
|---|---|---|
| Deploys to staging from CI | **Blocked** | Workflow, OIDC role, Terraform and rollback script written; linted, validated, plan-tested with a mocked provider. Never run against AWS, and CI has never run on GitHub (nothing is pushed). |
| Admin logs in with mandatory passkey/TOTP | **Met** | E2E with a virtual authenticator; `test_auth.py`, `test_passkeys.py`. Not tried with a physical authenticator. |
| Audit hash chain verifiable | **Met** | `test_audit.py`, `test_concurrency.py`; console button; scheduled check; WORM anchor (against an emulator). |
| S3 Test button passes against real AWS | **Blocked** | All steps pass against an emulator with a stubbed CDN, and each failure is detected. Outside that stub the test deliberately fails on an emulator. |

To unblock: follow `docs/runbooks/first-deploy.md`.

## M0 items

| Item | Status | Notes |
|---|---|---|
| Monorepo, tooling, CI/CD | Done | `apps/web` and `apps/mobile` arrive with M2 and M3 |
| Terraform base | Done, unapplied | VPC, RDS, Redis, S3, CloudFront, ECS, WAF, KMS, alarms |
| Design tokens | Done | CSS, Tailwind, JS, Dart |
| Django skeleton, user, RBAC | Done | `category` scope registers in M1 |
| Audit log | Done | |
| Staff security | Done | Passkey, TOTP, recovery, step-up, sessions, lockout, allowlist, geo, invitations |
| Four-eyes approvals | Done | Bulk delete and ads register their actions in M1 and M10 |
| Site config | Done | Logo and favicon need the media library (M1) |
| Integrations framework | Done | S3, SES, audit anchor, WAF |
| OpenAPI and clients | Done | TypeScript, Dart |
| Channels / WebSocket deployment | Moved to M1 | First consumer is media processing status |
| Per-app Sentry | API and workers done | Admin browser errors not yet reported |
| Queue-depth autoscaling | Not done | CPU and request scaling only; do with the M1 media queue |
| OpenTelemetry | Wired, untested | No collector available |

## Verification, 2026-11-23

206 API tests (91% coverage), 18 E2E, 97 contrast checks, 7 unit tests, 4 Terraform plan tests. mypy strict, ruff, Biome, Bandit, Semgrep, pip-audit, pnpm audit, OSV, Trivy (images and IaC), gitleaks, actionlint and shellcheck clean. Images run read-only, non-root, without capabilities. Auth and rate limiting also pass on cluster-mode Redis.

### Defects found by tests and fixed
- Passkey challenge restored by a full model save, so responses from synced passkeys were replayable.
- Geo-block raised inside a transaction, which would have undone the block and its alert.
- One shared rate-limit key let a strict endpoint exhaust the others.
- Settings and integration forms discarded typing after a save; actions clicked before the session loaded failed.
- PgBouncer image had no such user; passkey sign-in rejected the browser's payload; paginated responses did not match the schema.

### Known limits
- No load tests (M11). No ZAP scan (needs staging).
- The E2E browser is Chromium only.
- Swahili text was written by the engineer and needs a native editor.
