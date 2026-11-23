# Progress

Source of truth for what to build: [SPEC.md](SPEC.md). Two-tier acceptance: **LOCAL** (proven in CI or against stand-ins) closes a milestone; **STAGING** (real cloud and vendors) is tracked and never claimed unobserved. What needs a person: [human-actions.md](runbooks/human-actions.md).

| Milestone | LOCAL | STAGING |
|---|---|---|
| **M0 Foundation** | Done | Blocked: no AWS environment |
| **M0-CLOSE** | Done, pull request 7 | Blocked: no AWS environment |
| M1 to M11 | Not started | Not started |

## Next session starts here

1. Confirm pull request 7 is merged and `main` is green: `gh run list --branch main --limit 3`.
2. Start **M1** on a branch `m1-content-core`. First task: `packages/content-schema` (mission item A), because the API, the editor and both renderers depend on it: one JSON Schema, generated TypeScript + Zod and Dart, fixtures in `docs/content-fixtures/`. Then taxonomy and content models, workflow state machine, media pipeline, editor, public read API, seed data.
3. Commands: `docker compose up -d --wait`, then the checks in [README](../README.md#check). Build admin with **both** `API_PROXY_TARGET` and `REALTIME_PROXY_TARGET` immediately before e2e: `turbo run test` rebuilds it without them.
4. Open risks:
   - **Disk:** about 5 GB free of 32 GB in the Codespace; OpenSearch and ClickHouse together need about 3.5 GB. Use one profile at a time, or a larger machine.
   - **FFmpeg, Flutter and Terraform are not installed** in the container. Terraform 1.17.2 and Flutter 3.50.1 were used from a scratch directory.
5. Waiting for a person: an AWS environment (A1 to A3) and a dedicated test bucket (A8).

## Acceptance

| Criterion | LOCAL | STAGING |
|---|---|---|
| M0 Deploys to staging from CI | Workflow linted, Terraform plan-tested | Blocked (A1 to A3). The Deploy job is **skipped**, and a warning now says so |
| M0 Admin signs in with mandatory passkey/TOTP | Met: E2E with a virtual authenticator | Not tried with a physical authenticator (G4) |
| M0 Audit hash chain verifiable | Met | WORM anchor only against an emulator |
| M0 S3 Test passes against real AWS | Steps and failures proven against an emulator, where it deliberately fails | Blocked (A8) |
| M0-CLOSE Dependency policy, PR triage | Met: ADR-0019; pull requests 1 to 5 closed, 6 merged | n/a |
| M0-CLOSE Staff sockets | Met: `test_realtime.py`, E2E in Chromium | WebSockets through CloudFront VPC origins unobserved |
| M0-CLOSE Queue autoscaling | Met: `test_ops.py`, plan tests | No scaling event observed |
| M0-CLOSE OpenTelemetry | Met: `scripts/verify-otel.sh`, in CI | No production collector chosen |
| M0-CLOSE Admin browser errors | Met: E2E against a local sink | No Sentry project (A9) |
| M0-CLOSE Compose profiles | Met: every service started healthy; storage contract 7 of 7 | n/a |
| M0-CLOSE Screenshot gallery | Met: `docs/design/screens/m0/index.html` | n/a |

## M0 items carried forward

| Item | Where |
|---|---|
| `category` RBAC scope, logo and favicon | M1 |
| Bulk-delete and ads approvals | M1, M10 |
| Integration test details and hints are English only | M1, with item G (`docs/i18n/review.md`) |
| Swahili text needs a native editor | G1 |

## Defects found in M0-CLOSE and fixed

- **The API exported no HTTP spans**: instrumentation ran after Django read its middleware, and the ASGI instrumentation was not installed. Both fail silently.
- Query-string values were exported in spans.
- Tests published Celery messages to the development broker.
- Phone tables cut off columns; invitations showed role keys; the dashboard grid had a hole; header buttons shifted phone layouts by 60px.

## Verification, 2026-11-23

Baseline before any change: 206 API tests (90.88%), 18 E2E, 97 contrast checks, 7 admin unit tests, 4 Terraform plan tests, all green. CI runs on GitHub and passes on `main`.

After: 258 API tests (91.44%), 20 E2E, 97 contrast checks, 31 admin unit tests, 6 Terraform plan tests, 7 storage contract checks, all green.

Not run in this environment, only in CI: Dart client regeneration, Semgrep, OSV, Trivy.

### Known limits
- No load tests (M11). No ZAP scan (needs staging). E2E is Chromium only.
- `docs/design/screens/m0` covers every pair of device, theme and language, not all eight combinations.
