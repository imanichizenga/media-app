# Progress

Source of truth for what to build: [SPEC.md](SPEC.md). Two-tier acceptance: **LOCAL** (proven in CI or against stand-ins) closes a milestone; **STAGING** (real cloud and vendors) is tracked and never claimed unobserved. What needs a person: [human-actions.md](runbooks/human-actions.md).

| Milestone | LOCAL | STAGING |
|---|---|---|
| **M0 Foundation** | Done | Blocked: no AWS environment |
| **M0-CLOSE** | Done, pull request 7 (merged) | Blocked: no AWS environment |
| **M1 Content core** | Done, pull request 8 (merged) | Blocked: no AWS environment |
| **M2-DESIGN** | Approved with changes D1 to D7 on 2026-11-24 (see Human decisions) | n/a |
| **M2-THEMES** | Done, pull request 9 (merged 2026-11-24). Themes **approved (G2) 2026-11-24** | n/a |
| **M3 Mobile app** | Done, pull request 11 (merged 2026-11-26). **G2: approved with changes** 2026-11-25. Cold start and frames on the emulator: being measured (they were missing when this row said Done) | Needs C1, D1, G3 |
| **M3.1 Mobile polish** | Done (ADR-0044), merged with pull request 11: every test G2 asked for, platform goldens, gallery `m3-1.zip` | n/a |
| **M2 Website** | Done on `m2-website` (ADR-0045 to 0047), 2026-11-26: 58 website E2E tests in CI (`e2e-web`), all green locally; strict CSP without a nonce; Lighthouse every score 100, LCP 1.52 to 1.70 s; inside navigation with a red loading bar, no reloads; gallery `m2.zip` (214 screens). PR open; merges after **G2** on the M3.2 and M2 galleries | Needs A1 to A3, A8: Rich Results Test, real CDN purge, Search Console, ECS deploy |
| **M4 Identity & engagement** | In progress on `search` (ADR-0050), 2026-11-27: backend (Beem, Google, Apple providers with Test buttons; SMS codes with fraud limits; rotating tokens; likes, saves, comments, follows; views and readers), website (sign-in sheet, engagement, account) and seeded readers done and tested. App, 2026-11-27: sign-in by phone and SMS code, likes, comments, readers, account; `account_test.dart` (sign-in resumes the like, wrong code, SMS off, refused like goes back). Still to do: Google and Apple buttons in the app (their SDK packages), web challenge and app attestation before SMS, 5k likes/s load test | Needs real Beem, Google, Apple settings (runbooks/reader-sign-in.md) |
| M5 to M11 | Not started | Not started |

## Next session starts here

1. **M2 is done on `m2-website`; M3.2 on `m3-2`.** **Do not start M4** until the human approves the M3.2 and M2 galleries (G2). Then M4 Identity & engagement as a vertical slice (plan in the hand-off and the M2 pull request).
2. The toolchain lives in `/tmp/toolchain`, which is emptied when the Codespace stops. `support/scripts/mobile-toolchain.sh` makes it again in a minute. **All source is in `/workspaces` and pushed**; only SDKs, caches and builds are in `/tmp`.
3. Website checks: build admin (both proxy targets), then `WEB_LOCAL=1 API_PROXY_TARGET=http://127.0.0.1:8010 pnpm --filter @news/web... build`, then `pnpm --filter @news/e2e web`. Gallery: `SCREENS=m2 pnpm --filter @news/e2e web`, then `node contact-sheet.mjs m2` in `support/tests/e2e`.
4. Contract migration `site_config/0003`: delete the old `identity` row. Ship it in the release **after** this one.
5. Commands: `docker compose --profile storage up -d --wait`, then the checks in [README](../../README.md#check). E2E needs FFmpeg and the storage profile, and its seeding takes minutes. Build admin with **both** `API_PROXY_TARGET` and `REALTIME_PROXY_TARGET` immediately before e2e: `turbo run test` rebuilds it without them. Backend tests share one Redis: never run them in parallel.
6. Open risks:
   - **Never run against real AWS:** MediaConvert, GuardDuty, CloudFront purge, every IAM and bucket policy, and the load balancer rule for `/theme/*`. Plan-tested only.
   - The hosted Android emulator sometimes goes `offline` in the middle of a test (2026-11-26: twice in one job, in different tests, with the same commit green before). The job retries once. If it keeps happening: a larger runner, or fewer services beside the emulator.
   - `uv` could not reach PyPI from this Codespace on 2026-11-24 (`curl` could). `UV_OFFLINE=1` works with the lockfile.
7. Waiting for a person: an AWS environment (A1 to A3); a dedicated test bucket (A8); a native Swahili editor (G1, 1007 strings); the real name and logos (G6).

## Human decisions

Recorded as given on **2026-11-24**.

> **G6 Brand.** Brand name, logos and the brand colour are DATABASE-DRIVEN (admin), never hardcoded. The brand direction is WHITE, RED and BLACK, with RED as the dominant brand colour. Provide THREE design themes selectable in admin. Default: "Red Signature" with a deep red. The placeholder name stays "Mfano News" until the client sets the real one in admin.

> **G2 Design.** The layout, structure and components in PR 9 are APPROVED WITH CHANGES D1–D7. Colour direction CHANGES per §2 (the theme system). The three themes need a fresh G2 sign-off on their gallery, but that sign-off does NOT block M3: the app is built against the theme contract, so themes are data.

> **Open design questions.** Tabs: Nyumbani, Video, Gundua, Hifadhi, Wewe — approved. Comments: a sheet over the story on the app (Instagram-style); a right-hand drawer on desktop — approved. Shorts are always dark, in every theme — approved.

The full text of the task these come from is summarised in [design/public-experience.md](design/public-experience.md) (rules, D1 to D7) and ADR-0029 onward.

> **G2 themes, 2026-11-24:** "i also approve your theme and design, now proceed with mobile, now in mobile i need more strong ui design". Same message: galleries may be zipped to free space, and `/tmp` may be used as long as no file is lost.

> **G2 app (PR 11), 2026-11-25:** "APPROVED WITH CHANGES S1–S5, N1–N7, V1–V4 below. Merge PR 11 only after M3.1 passes. Write ADR-0044 "Space and native conventions", superseding the parts of ADR-0043 it changes: display size on Home, feeds and categories sharing one row." Two principles: "SPACE IS FOR NEWS: chrome must never crowd out content." "NATIVE FIRST: each platform must feel like it belongs on that platform, while the brand, typography and card anatomy stay identical." The changes are listed in [ADR-0044](adr/0044-space-and-native.md).

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
| M0-CLOSE OpenTelemetry | Met: `support/scripts/verify-otel.sh`, in CI | No production collector chosen |
| M0-CLOSE Admin browser errors | Met: E2E against a local sink | No Sentry project (A9) |
| M0-CLOSE Compose profiles | Met: every service started healthy; storage contract 7 of 7 | n/a |
| M0-CLOSE Screenshot gallery | Met: `support/docs/design/screens/m0.zip` | n/a |
| M1 1 GB upload resumes after a cut and plays as adaptive HLS | Met: `python -m tests.live_upload` on 2026-11-24. 69 of 138 parts kept, each part sent once, four renditions decode to the last frame | Needs A8, A10 |
| M1 EXIF removed | Met: `test_media.py` | n/a |
| M1 Every YouTube address form normalises | Met: `test_youtube.py` | n/a |
| M1 Workflow permission matrix | Met: `test_content.py` | n/a |
| M1 Block fixtures validate on the API | Met: `test_blocks.py`; also TypeScript, Dart, editor round trip, web renderer | n/a |
| M1 Public read: query counts and cache headers | Met: `test_public_api.py` | CDN hit rate and purge delay unobserved |
| M1 Transcoding provider | FFmpeg end to end; MediaConvert against stubs | Needs A10: **AWS MediaConvert** → Test |
| M1 Malware scan | ClamAV protocol and GuardDuty verdicts against stubs; bucket policy plan-tested | Needs A10 |
| M1 Purge and revalidation sender | Met: `test_delivery.py`; receiver in M2 | Real purge unobserved |
| M1 Seed data | Met: `test_seed_demo.py`, 300 posts | n/a |
| M1 Category-scoped roles | Met: `test_taxonomy.py`, E2E | n/a |
| M1 Screenshot gallery | Met: `support/docs/design/screens/m1.zip` | n/a |

| M2-THEMES Derivation parity in Python, TypeScript and Dart | Met: shared vectors, `test_theme.py`, `theme.test.mjs`, `theme_test.dart` | n/a |
| M2-THEMES Any valid colour passes AA in every theme | Met: property tests over random colours | n/a |
| M2-THEMES SVG logos cleaned | Met: `test_brand.py`, 14 malicious samples | n/a |
| M2-THEMES Publish, four eyes, rollback, hashed stylesheet, no flash | Met: `test_brand.py`, E2E | CDN behaviour of `/theme/*` unobserved |
| M2-THEMES Gallery, axe, no sideways scroll | Met: 320 prototype screens, 0 findings | n/a |

| M2 Every public page server-rendered with ISR; signed, single-use revalidation | Met: `web/test`, `publish.spec.ts` (publish in admin → page updates) | Real CloudFront purge unobserved |
| M2 Strict CSP without a nonce (a CDN-kept nonce is no secret): `script-src 'self'`, Trusted Types, reports logged; HSTS; no third-party scripts | Met: `web/test/safety.test.ts`, `document.test.ts`; `seo.spec.ts` checks every page for inline scripts and a real browser for violations | Violation reports from real readers |
| M2 Structured data, sitemaps (News, image, video), RSS, hreflang, redirects | Met: schema validator, Google's required and recommended fields (`web/test/google.ts`, read 2026-11-26) on every page, News sitemap against Google's XSD; `seo.spec.ts` | Rich Results Test, Search Console |
| M2 axe in both schemes, no sideways scroll at 320 px, skeleton matches the page (8 px, CLS < 0.05) | Met: `site.spec.ts`, `states.spec.ts` | n/a |
| M2 Space rule: lead headline above the bottom bar at 360×640 | Met: `site.spec.ts` | n/a |
| M2 Lighthouse (phone, throttled, median of 3) on Home, Article, Category, Video, Live: LCP < 2.0 s, CLS < 0.05, TBT < 150 ms, JS < 120 KB; performance ≥ 95, accessibility and SEO 100, best practices ≥ 95 | Met 2026-11-26: LCP Home 1517 ms, Article 1595, Category 1587, Video 1695, Live 1588; CLS ≤ 0.002; TBT ≤ 5 ms; 6.6 KB script; every score 100. Fonts subsetted (65 KB, was 106) and an 800 px picture: they were the 0.4 s that put Video at the line | Field data needs real readers |
| M2 Guards for the document layer: no framework runtime or flight data, islands < 6 KB, true 404/301/503, complete without script, inside navigation falls back | Met: `contract.spec.ts`, `document.test.ts`, `site.spec.ts`, `states.spec.ts`; Next pinned, Dependabot patches only, [upgrade-next.md](runbooks/upgrade-next.md) | n/a |
| M2 The same product as the app (ADR-0044, M3.2) | Met: one-line meta (R2), rail titles (R3), no play buttons (R1), a row of sections that says it goes on, "Open in app" banner; differences in [consistency.md](design/consistency.md) | n/a |
| M2 Terraform plan tests for `web.tf`; the image builds and passes Trivy | Met in CI (`infra`, `images`) | ECS deploy needs A1 to A3 |
| M2 Gallery | Met: `support/docs/design/screens/m2.zip` (214): every page, phone and desk, light and dark, sw and en; three themes on Home, Article, Shorts, Category; skeleton, empty, offline, 404, 503; the app beside the web | Waiting for G2 |

| M3 Every screen a guest needs, sw and en, light and dark, three themes | Met: 128 goldens and checks | n/a |
| M3 Every content fixture renders | Met, except `long-article` as a picture (its blocks are covered by the others) | n/a |
| M3 Offline, saved articles, forced update, kill switches, theme at next cold start | Met: `app_test.dart`; on an emulator and a simulator in CI | Needs a published app |
| M3 iOS | Built without a signature; integration tests on a simulator against **recorded** answers (macOS runners cannot run the API's services) | Needs C1 |
| M3 Cold start < 1.5 s, 60 fps | **Not measured on a phone** | G3 |
| M3 Certificate pinning | Met against a test certificate | Needs A1 and real pins |
| M3 App and universal links | Files served and tested; warm and cold opening tested | Needs real ids and a domain |

## Carried forward

| Item | Where |
|---|---|
| Notification visuals use the theme and logo | M6 |
| Old `identity` settings row deleted (contract) | Next release |
| Ads approvals | M10 |
| Swahili text needs a native editor | G1, `support/docs/i18n/review.md` |
| Details of a failed integration test stay in the vendor's English; hints are bilingual | Decided |
| Content renderer in Flutter over all fixtures | M3 |
| Notifications on workflow transitions (the signal exists) | M6 |
| Search (ADR-0049) on branch `search`: API, OpenSearch + Postgres fallback, website page done; app field on Explore done 2026-11-27 (headlines while typing, results with filters, recent searches on the phone; `search_test.dart` on Android and iOS); Terraform for the domain and the million-story load test still to do | `search` |

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
- `support/docs/design/screens/m0` covers every pair of device, theme and language, not all eight combinations.
