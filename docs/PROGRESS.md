# Progress

Source of truth for what to build: [SPEC.md](SPEC.md). Two-tier acceptance: **LOCAL** (proven in CI or against stand-ins) closes a milestone; **STAGING** (real cloud and vendors) is tracked and never claimed unobserved. What needs a person: [human-actions.md](runbooks/human-actions.md).

| Milestone | LOCAL | STAGING |
|---|---|---|
| **M0 Foundation** | Done | Blocked: no AWS environment |
| **M0-CLOSE** | Done, pull request 7 (merged) | Blocked: no AWS environment |
| **M1 Content core** | Done, pull request 8 (merged) | Blocked: no AWS environment |
| **M2-DESIGN** | Approved with changes D1 to D7 on 2026-11-24 (see Human decisions) | n/a |
| **M2-THEMES** | In progress, branch `m2-design`, pull request 9 | n/a |
| M2 to M11 | Not started | Not started |

## Next session starts here

1. Is the design approved? Spec: [design/public-experience.md](design/public-experience.md), gallery: `docs/design/screens/m2-design/index.html`. Record the answer, with its date, here and in human-actions G2. **Do not build website or app screens before it.**
2. Meanwhile, on a branch `m2-website`, work that has no screens: the `apps/web` skeleton (Next.js, strict CSP, i18n, no pages yet), the signed revalidation receiver (`POST /api/revalidate`: HMAC, five-minute window, single use), JSON-LD builders with a schema validator in CI, sitemaps (index, news, image, video), RSS, robots, redirects through `/content/resolve`, the image loader, Lighthouse CI wiring, Terraform for the website. Cards and their skeletons are already in `packages/ui/src/news.tsx`.
3. Commands: `docker compose --profile storage up -d --wait`, then the checks in [README](../README.md#check). E2E needs FFmpeg and the storage profile. Build admin with **both** `API_PROXY_TARGET` and `REALTIME_PROXY_TARGET` immediately before e2e: `turbo run test` rebuilds it without them.
4. Open risks:
   - **Disk:** about 3 GB free of 32 GB in the Codespace. OpenSearch and ClickHouse together need about 3.5 GB. Use one profile at a time, or a larger machine.
   - **Flutter and Terraform are not installed** in the container. Terraform 1.17.2 and Flutter 3.50.1 were used from a scratch directory. M3 needs Flutter permanently.
   - **Never run against real AWS:** MediaConvert, GuardDuty, CloudFront purge, and every IAM and bucket policy. Plan-tested only.
5. Waiting for a person: an AWS environment (A1 to A3), a dedicated test bucket (A8), a native Swahili editor (G1, 934 strings). Brand name, logo and accent colour (G6) are needed for M2-DESIGN.

## Human decisions

Recorded as given on **2026-11-24**.

> **G6 Brand.** Brand name, logos and the brand colour are DATABASE-DRIVEN (admin), never hardcoded. The brand direction is WHITE, RED and BLACK, with RED as the dominant brand colour. Provide THREE design themes selectable in admin. Default: "Red Signature" with a deep red. The placeholder name stays "Mfano News" until the client sets the real one in admin.

> **G2 Design.** The layout, structure and components in PR 9 are APPROVED WITH CHANGES D1–D7. Colour direction CHANGES per §2 (the theme system). The three themes need a fresh G2 sign-off on their gallery, but that sign-off does NOT block M3: the app is built against the theme contract, so themes are data.

> **Open design questions.** Tabs: Nyumbani, Video, Gundua, Hifadhi, Wewe — approved. Comments: a sheet over the story on the app (Instagram-style); a right-hand drawer on desktop — approved. Shorts are always dark, in every theme — approved.

The full text of the task these come from is summarised in [design/public-experience.md](design/public-experience.md) (rules, D1 to D7) and ADR-0029 onward.

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
| M1 1 GB upload resumes after a cut and plays as adaptive HLS | Met: `python -m tests.live_upload` on 2026-11-24. 69 of 138 parts kept, each part sent once, four renditions decode to the last frame | Needs A8, A10 |
| M1 EXIF removed | Met: `test_media.py` | n/a |
| M1 Every YouTube address form normalises | Met: `test_youtube.py` | n/a |
| M1 Workflow permission matrix | Met: `test_content.py` | n/a |
| M1 Block fixtures validate on the API | Met: `test_blocks.py`; also TypeScript, Dart, editor round trip, web renderer | n/a |
| M1 Public read: query counts and cache headers | Met: `test_public_api.py` | CDN hit rate and purge delay unobserved |
| M1 Transcoding provider | FFmpeg end to end; MediaConvert against stubs | Needs A10: **AWS MediaConvert** → Test |
| M1 Malware scan | ClamAV protocol and GuardDuty verdicts against stubs; bucket policy plan-tested | Needs A10 |
| M1 Purge and revalidation sender | Met: `test_delivery.py` | Receiver in M2 |
| M1 Seed data | Met: `test_seed_demo.py`, 300 posts | n/a |
| M1 Category-scoped roles | Met: `test_taxonomy.py`, E2E | n/a |
| M1 Screenshot gallery | Met: `docs/design/screens/m1/index.html` | n/a |

## Carried forward

| Item | Where |
|---|---|
| Ads approvals | M10 |
| Swahili text needs a native editor | G1, `docs/i18n/review.md` |
| Details of a failed integration test stay in the vendor's English; hints are bilingual | Decided |
| Content renderer in Flutter over all fixtures | M3 |
| Notifications on workflow transitions (the signal exists) | M6 |
| Search endpoint answers `available: false` | M8 |

## Defects found in M1 and fixed

- **The console could never have uploaded in AWS**: its role had no S3 access, its image missed two workspace packages, and the bucket had no CORS rule.
- **A waiting scan downloaded the whole file every 20 seconds**, up to 8 GB a time.
- **A failed purge was never retried**, and a broken website kept the CDN stale too.
- The shared schema accepted links such as `/\evil.example`, which browsers read as another site.
- Retrying a failed MediaConvert job reused its token, so AWS would have returned the failed job.
- Moving a picture's focal point put it back into scanning and blocked publishing; the editor did not notice when a file became ready.
- The calendar asked for 100 posts in editing order and silently dropped the rest of a busy week.
- Skeletons in the content list and the article were invisible: a plain space has no height.
- Dialog backdrops had not drawn since M0; logos lost their transparency; scheduling used the laptop's clock; an error in the live-update dialog appeared behind it; the editor scrolled sideways on phones; Zod asked for `eval`.

## Defects found in M0-CLOSE and fixed

- **The API exported no HTTP spans**: instrumentation ran after Django read its middleware, and the ASGI instrumentation was not installed. Both fail silently.
- Query-string values were exported in spans.
- Tests published Celery messages to the development broker.
- Phone tables cut off columns; invitations showed role keys; the dashboard grid had a hole; header buttons shifted phone layouts by 60px.

## Verification, 2026-11-23

Baseline before any change: 206 API tests (90.88%), 18 E2E, 97 contrast checks, 7 admin unit tests, 4 Terraform plan tests, all green. CI runs on GitHub and passes on `main`.

After: 258 API tests (91.44%), 20 E2E, 97 contrast checks, 31 admin unit tests, 6 Terraform plan tests, 7 storage contract checks, all green.

M1, 2026-11-24: 726 API tests, 37 E2E, 218 web unit tests, 8 Terraform plan tests, all green.

Not run in this environment, only in CI: Dart client regeneration, Semgrep, OSV, Trivy.

### Known limits
- No load tests (M11). No ZAP scan (needs staging). E2E is Chromium only.
- `docs/design/screens/m0` covers every pair of device, theme and language, not all eight combinations.
