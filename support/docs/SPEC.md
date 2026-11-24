# MISSION

You are a principal engineer and product designer (ex-Meta / Twitter / NYT-digital calibre) building a production-grade NEWS & MEDIA PLATFORM for a top East African journalism brand (audience: millions of users, Tanzania-first, Swahili + English). The brand name, logo and colors are configurable in the admin; refer to them as {{BRAND_NAME}} / design tokens. You will deliver four products in ONE monorepo:

1. Backend API — Python / Django (+ Django REST Framework, Celery, Django Channels)
2. Mobile app — Flutter (iOS + Android)
3. Public website — Next.js (SEO is the #1 priority)
4. Administration console — Next.js (separate app, separate domain, extreme security)

The quality bar: this is the flagship work that proves what an elite engineer can do. UI/UX quality, performance, security and scalability are NON-NEGOTIABLE priorities. Do nothing partially. No placeholder screens, no "TODO: implement later" in delivered milestones, no silently stubbed integrations.

# 1. HOW YOU MUST WORK

- Work in the phased milestones defined in section 15. Finish each milestone completely (code + tests + docs) before starting the next. Track status in /docs/PROGRESS.md (milestone, items, done/blocked, notes).
- Record every significant technical decision as an ADR in /docs/adr/NNNN-title.md (context, decision, alternatives, consequences).
- EXTERNAL APIs CHANGE. Before implementing any integration (Beem, Meta/Instagram Graph API, AWS IVS, MediaConvert, FCM HTTP v1, Google Sign-In, Sign in with Apple, YouTube oEmbed, AdMob/Ad Manager, Meta Audience Network, AppLovin MAX), read the CURRENT official docs and pin the API version. Do not rely on memory for endpoints, field names, permission names or SDK APIs. Beem docs: https://docs.beem.africa/
- Every integration sits behind a provider interface (Strategy pattern) so providers can be swapped or added without touching business logic.
- Use the latest STABLE versions at build time and pin them (lockfiles committed): Python 3.13+, Django LTS (5.2+), DRF, Celery, Channels, PostgreSQL 17, Redis 7+, Next.js latest stable (App Router, React Server Components), TypeScript strict, Flutter latest stable, Dart 3.
- Code quality: SOLID, clean module boundaries, typed everywhere (mypy strict for Python domain code, TS strict, Dart strict analysis), no business logic in views/widgets, service layer + selectors pattern in Django, repository/use-case layering in Flutter.
- If something is genuinely impossible to verify without a credential (e.g., Meta app review), implement it fully, make the "Test" button report the exact missing prerequisite, and document the manual step in /docs/runbooks/.
- Only ask the human when truly blocked. Otherwise make the best-practice decision, document it in an ADR, and continue.

# 2. PRODUCT SUMMARY

A news & information platform where journalists publish many content types (articles, breaking news, videos, galleries, live blogs, live streams, opinion, short vertical videos, YouTube embeds, Instagram-imported posts). Anyone can browse without an account. Signing up is only required to ENGAGE (like, comment, bookmark, follow, etc.) and is near-frictionless: phone number + OTP (SMS via Beem), Google, or Sign in with Apple (required on iOS by App Store guideline 4.8). Admins control which engagement types are allowed per post. Admins moderate content and users, configure every integration from the database with a "Test" button, see real-time analytics and complete logs.

# 3. ARCHITECTURE & STACK (DECIDED — DO NOT RE-LITIGATE)

Backend
- Django + DRF (REST, OpenAPI 3.1 via drf-spectacular). The OpenAPI schema is the contract: generate a typed TypeScript client (packages/api-client) for web/admin and a Dart client for Flutter. CI fails if generated clients are stale.
- ASGI: Django served by Gunicorn with Uvicorn workers; a SEPARATE Channels/WebSocket deployment for realtime (counters, presence, notifications in-app), Redis channel layer.
- Celery + Redis broker (SQS-ready via config) for async work; Celery Beat for schedules. Separate queues: critical (OTP, push breaking), media, notifications, analytics, sync, default.
- PostgreSQL 17 (Amazon RDS Multi-AZ) + PgBouncer + read replica(s) via a Django DB router (reads that tolerate lag go to replicas).
- Redis (ElastiCache, cluster mode) for cache, rate limits, counters, presence, feeds, locks.
- Search: Amazon OpenSearch Service (Swahili + English analyzers, synonyms, typo tolerance, "more like this" for related content).
- Analytics store: ClickHouse (ClickHouse Cloud on AWS or self-managed) fed by an event pipeline (API ingest → Kinesis Data Streams or Redis Streams → ClickHouse). Raw events retained 90 days (configurable), aggregates kept forever.
- Django's built-in admin is NOT the admin product. It is disabled in production (or only reachable for superusers over VPN/IP allowlist).

Media & live (AWS)
- S3 (private buckets, Block Public Access ON) + CloudFront with Origin Access Control for ALL media delivery.
- Uploads: direct-to-S3 presigned multipart uploads from clients (resumable, with progress); API never proxies file bytes.
- Video: AWS Elemental MediaConvert → adaptive HLS (CMAF) ladder 240p/360p/480p/720p/1080p (+ vertical ladder for shorts), poster frames, thumbnail sprite for scrubbing, duration/metadata extraction. Job completion via EventBridge → API webhook (signed) → post becomes playable.
- Images: variants generated on upload (Celery with pyvips or a Lambda with sharp): AVIF + WebP + JPEG at widths 320/640/960/1280/1920, blurhash placeholder, dominant color. ALWAYS strip EXIF/GPS (journalist safety). Validate by magic bytes; malware-scan uploads (ClamAV or Amazon GuardDuty Malware Protection for S3) before processing.
- Live: Amazon IVS (low-latency channels) + IVS Chat + auto-record to S3 → automatic VOD post after the stream ends.

Frontend
- Web + Admin: Next.js App Router, React Server Components, TypeScript strict, Tailwind CSS driven by shared design tokens, Radix primitives for accessible behaviour, TanStack Query for client data, Zod validation. pnpm + Turborepo.
- Mobile: Flutter, Riverpod (state), go_router (deep links), dio (HTTP + interceptors), freezed/json_serializable, drift (offline cache), flutter_secure_storage, cached_network_image with sized decode, video_player (HLS) and the Amazon IVS player/broadcast SDKs wrapped via platform channels if no maintained Flutter plugin exists (Kotlin + Swift), firebase_messaging + flutter_local_notifications, google_sign_in, sign_in_with_apple.

Infrastructure
- Terraform for ALL AWS resources; environments: dev, staging, prod (separate AWS accounts recommended).
- ECS Fargate for API, WebSocket, Celery workers (autoscaling on CPU/queue depth); web and admin on ECS or Vercel (document choice in ADR; admin MUST support IP allowlisting).
- AWS WAF in front of CloudFront/ALB, AWS Shield Standard, Secrets Manager + KMS, CloudWatch, OpenTelemetry tracing, Sentry for errors (all 4 apps).
- GitHub Actions CI/CD with required checks; blue/green or rolling deploys with automatic rollback on health-check failure; DB migrations must be backwards-compatible (expand/contract).

# 4. MONOREPO LAYOUT

/apps/api            Django project (apps listed in §9)
/apps/web            Next.js public website
/apps/admin          Next.js administration console
/apps/mobile         Flutter app
/packages/design-tokens   Single source of truth (JSON, Style Dictionary) → Tailwind theme (web/admin) + Dart ThemeData/ThemeExtension (Flutter)
/packages/api-client      Generated TS client
/packages/ui              Shared React components (web + admin) incl. skeleton variants
/infra/terraform, /infra/lambda
/docs (architecture, adr, runbooks, api, design, PROGRESS.md)
/tests/load (k6), /tests/e2e (Playwright)

# 5. DESIGN SYSTEM & UI/UX — TOP PRIORITY

Design philosophy: an editorial, content-first, calm interface. Zero noise. The content is the hero. A user coming from the mobile app to the website (or vice versa) must feel it is the same product: same tokens, typography, iconography, card anatomy, engagement bar, colors, motion.

Tokens (packages/design-tokens) — generate for all platforms
- Typography: a refined serif for headlines (e.g., Newsreader or Source Serif 4) + a highly legible sans for UI/body (e.g., Inter). Both support Swahili characters. Self-hosted, subsetted. Type scale with fixed roles: display, headline-L/M/S, title, body-L/M, label, caption. Respect OS dynamic type / user font scaling.
- Color: neutral grayscale foundation + ONE brand accent (configurable). Red is RESERVED for BREAKING and LIVE only, so it keeps its meaning. Semantic tokens (bg, surface, surface-raised, text-primary/secondary/tertiary, border, accent, success, warning, danger, live). Full light + dark themes, follow system by default, user override. WCAG 2.2 AA contrast minimum.
- Spacing on a 4/8pt grid; radii 8/12/16/24; elevation via subtle borders + shadows (dark mode uses surface tones, not shadows).
- Motion: 150–250ms, standard easing, shared-element transitions from card to article where possible, respects "reduce motion".
- Iconography: one consistent outlined icon set (e.g., Lucide on web, matching set in Flutter); filled variant for active states (like = filled heart).
- Number formatting: compact counts (1.2K, 3.4M) localized for sw/en; relative timestamps ("dakika 5 zilizopita" / "5m ago").

SKELETON RULE (strict)
- No spinners for content loading anywhere. The ONLY loader is a screen skeleton. (Inline button "pending" states are allowed.)
- Every content component exports a Skeleton variant built from the SAME layout primitives and dimensions as the real component (same paddings, aspect ratios, line counts, avatar sizes). Screen skeletons are composed from component skeletons, so structure matches exactly. The number of skeleton items fills the viewport.
- Subtle shimmer, disabled under reduce-motion. Images load with blurhash/dominant color → fade-in, never layout shift.
- Enforce with tests: (web) Playwright test measures bounding boxes of skeleton vs loaded state per screen — key element positions must match within tolerance and CLS must be < 0.05; (Flutter) golden tests for each screen in skeleton and loaded states.

Interaction patterns
- Engagement UI borrows proven patterns users already know: Twitter/X-style action row under posts (like, comment, repost/quote, bookmark, share, with counts) and Instagram-style comments bottom sheet (threaded one level deep, like comments, reply, pin, author badge, "view replies", composer pinned at bottom with keyboard handling). Only ENABLED engagement types render (see §9.6); disabled ones leave no gaps.
- Optimistic UI for every engagement with rollback on failure; haptic feedback on mobile (light impact on like).
- "Intent resume" auth gating: when a guest taps an engagement action, show a beautiful bottom sheet ("Sign in to like this story") with Phone, Google and Apple (iOS) in ONE sheet. After successful login, automatically complete the original action and return the user to exactly where they were. Never navigate to a full-screen login wall.
- Empty, error and offline states are designed (illustration + one clear action), never raw error text.
- Accessibility: screen-reader labels, focus order, 44×44pt/48dp minimum tap targets, captions support for video.

# 6. MOBILE APP (FLUTTER)

First launch (shown ONCE, every step skippable via a persistent "Skip"):
1. Welcome — a beautiful value proposition showing real top stories behind a gradient (what the app is: trusted news, live, video).
2. Language — Kiswahili / English (default Kiswahili).
3. Topics — pick categories (chips with icons); powers cold-start personalization; stored on device for guests and merged into the account on signup.
4. Notifications soft-prompt — explain value (breaking news, live alerts) BEFORE the OS permission dialog; if declined, re-ask contextually later (e.g., after following a topic), never nag.
Then land directly on the Home feed as a guest. Never open on a login screen.

Navigation: bottom bar with 5 tabs
- Home: top "Live now" rail (circular avatars with a red animated ring, like IG stories), breaking-news banner when active, segmented tabs "For You" / "Latest" + horizontally scrollable category chips. Mixed feed: lead story card (large image), standard cards, compact cards, video cards, gallery cards, live-blog cards (pulsing LIVE label + latest update), "Top stories" carousels, inline video strip. Pull to refresh, infinite scroll with cursor pagination, prefetch next page and first images.
- Video: two modes — vertical full-screen Shorts feed (swipe, autoplay muted with tap to unmute, preloading next 2 items' first HLS segments) and long-form video list.
- Explore/Search: trending searches, categories grid, trending stories, journalists to follow; instant search with debounced suggestions, filters (type, category, date).
- Saved: bookmarks + offline-downloaded articles + reading history.
- You: profile, followed topics/journalists, notification preferences (granular), language, theme, data saver mode (lower video quality, no autoplay on cellular), account (link phone/Google/Apple), privacy (download my data, delete account — required by App Store/Play), legal. For guests: a friendly sign-in card plus settings that work without an account.

Article reader
- Rich content blocks rendered NATIVELY in Flutter from structured JSON (no WebView for article bodies): paragraph, heading, image (pinch-zoom, caption, credit), gallery, HLS video, YouTube (lite facade → player on tap), quote/pull-quote, embedded social posts, table, callout, fact box, related link, live-blog updates timeline (auto-updating via WebSocket).
- Header: category label, headline (serif), standfirst, byline (avatar, verified badge, follow), published/updated time, reading time. "Updated" and "Correction" notes displayed transparently.
- Sticky bottom engagement bar (only enabled types), share sheet with deep link + OG image, text-size control, listen/read progress indicator, "Next story" prefetching, related stories at the end.
- Sensitive media: blurred with "View" tap-through when flagged by editors.

Live
- Viewer: IVS low-latency player, live viewer count, IVS chat overlay (if comments allowed for that live), reactions burst animation, "LIVE" pill, share; after the stream ends it turns into the recorded VOD.
- Go Live (only users with the go_live permission): pre-flight screen (title, category, thumbnail, engagement settings, camera/mic check, network quality), countdown, in-stream controls (flip camera, mute, end, viewer count, moderate chat: delete message, timeout user). Also expose RTMPS ingest URL + stream key (revealed on demand, rotatable) for studio/OBS streaming. Followers get a push when a journalist goes live.
- Non-journalists can request go-live permission in-app; admin approves/denies (§8).

Auth (mobile)
- Phone: country picker defaulting to +255 (configurable list of allowed countries), as-you-type formatting, E.164 validation. OTP screen: 6-digit boxes, Android SMS Retriever API autofill (OTP SMS template includes the app hash), iOS one-time-code autofill, resend countdown (60s, configurable), clear error states.
- Google Sign-In and Sign in with Apple (iOS required; offered on Android too as optional).
- New users: only ask for display name after first login (prefilled from Google/Apple), optional avatar. Username auto-generated, editable later. Accept community guidelines + privacy policy with a single checkbox.
- Device ID used for guest personalization; merged on signup/login.

Performance (mobile) budgets
- Cold start to first meaningful content < 1.5s on a mid-range Android (show cached feed from drift instantly, refresh in background).
- 60fps scrolling (no jank in DevTools profile on feed and Shorts), image decode at display size (cacheWidth), JSON parsing of large payloads in isolates, const widgets, keys on list items, list virtualization.
- App size budget: Android < 30MB download (split per ABI), iOS documented.
- Offline: last feed + saved articles readable offline; engagement actions queued and replayed when online.

# 7. WEBSITE (NEXT.JS) — SEO FIRST

Pages: Home (editorial layout: lead story + secondary grid, breaking ticker, live rail, latest river, video strip, category sections, most-read), Category, Tag, Story/Topic cluster (ongoing events), Article, Video, Shorts, Live/Live blog, Journalist (author) page, Search, Saved, Profile/settings, Auth sheet (same patterns as mobile, modal not page), static pages (about, editorial policy, corrections policy, contact, privacy, terms).

Same IA and visual language as the app; mobile web feels like the app.

SEO requirements (all mandatory)
- Server-rendered HTML for every public page (RSC + ISR). On publish/update/unpublish, the API fires a signed on-demand revalidation webhook to Next.js and purges CDN paths. Anonymous pages served from the CDN with s-maxage + stale-while-revalidate.
- Structured data (JSON-LD): NewsArticle (headline, images ≥1200px wide in 16:9/4:3/1:1, datePublished, dateModified, author as Person with URL, publisher Organization with logo), LiveBlogPosting for live blogs, VideoObject (including YouTube embeds and HLS videos), BreadcrumbList, Organization, WebSite with SearchAction, ProfilePage for authors.
- Google News sitemap (articles from last 48h), sitemap index split by type/date, image and video sitemaps, robots.txt, RSS/Atom feeds per category.
- hreflang for sw/en (+ x-default), canonical URLs, stable slugs with automatic 301 redirects on slug/category change (redirect table, admin-editable).
- Meta: title templates, descriptions, Open Graph + Twitter cards with dynamically generated OG images (headline + brand), robots meta with max-image-preview:large (Google Discover), noindex for search/filter pages.
- E-E-A-T: rich author pages (bio, expertise, social links), visible publish/updated dates, corrections notes, editorial policy pages linked from the footer.
- IndexNow ping on publish (configurable) and Google Search Console verification field in settings.
- Admin SEO panel per post: SEO title/description override, focus keyword, Google snippet preview, social preview, readability and SEO checks (title length, description length, image alt text present, internal links).

Web performance budgets (enforced in CI with Lighthouse CI on key pages)
- LCP < 2.0s (4G mid device), INP < 200ms, CLS < 0.05, JS shipped on article pages < 120KB gzipped.
- Images via a custom Next.js loader that uses the pre-generated CloudFront variants (AVIF/WebP, srcset, sizes), priority hint for LCP image only.
- YouTube via lite facade (youtube-nocookie, iframe only on click). Third-party scripts deferred; ads (when enabled) load after the main content, with reserved space only when ads are on.
- Web push via FCM (soft-prompt first, never on first page load).

# 8. ADMINISTRATION CONSOLE (NEXT.JS) — EXTREME SECURITY

Separate deployment on its own domain (e.g., admin.{{domain}}), own auth realm, never shares cookies with the public site. Calm, dense-but-clear design using the same tokens (in its own "admin" density mode), keyboard shortcuts, command palette (⌘K).

Sections
- Dashboard: realtime KPIs (users online now — logged-in and guests, DAU, new signups today, top live streams, trending posts, moderation queue size, integration health).
- Content: posts list (filters by status/type/category/author/date), block editor (Tiptap/ProseMirror on web) producing the structured JSON consumed natively by Flutter and web, autosave every few seconds, revision history with visual diff and restore, soft edit-lock ("Asha is editing"), scheduling and embargo, breaking-news flag (with optional push), live-blog update composer, mobile + desktop preview frames, SEO panel, engagement policy panel, content warnings/sensitive-media flag, corrections/update notes, editorial calendar view, bulk actions.
- Media library: uploads with progress, processing status (scanning → transcoding → ready / failed with retry), alt text and credits required for images, focal point selection for smart crops, usage tracking ("used in 3 posts"), YouTube URL import (paste any YouTube URL form: watch, youtu.be, shorts, live, embed → normalized ID + oEmbed metadata).
- Live: active streams monitor (viewer counts, health), force-stop, chat moderation, go-live permission requests (approve/deny with reason, expiry optional), stream key management.
- Categories & tags: hierarchical categories (max 3 levels), drag-and-drop ordering, per-language names/descriptions/slugs, icon + color, SEO metadata, default engagement policy, assigned section editors, visibility (public/hidden/archived), merge and move with automatic redirects; curated flat tags with synonyms and merge; Story/topic clusters for ongoing events.
- Moderation: unified queue (reported comments, posts, users, auto-flagged items) with SLA timer, item context (thread, user history, prior strikes), one-click actions with reason codes, bulk actions, rules editor (§9.7), appeals queue, moderation log.
- Users: search and filter users, profile view with activity timeline, sessions/devices, login history, strikes, role assignment, verification badges, suspend/ban (temporary/permanent), shadow-ban, force logout, data export/deletion requests.
- Staff & roles: invite-only staff creation, RBAC role editor (§9.2), category-scoped permissions.
- Engagement policies: global defaults, per-category defaults, global kill switches (e.g., disable all comments site-wide during a crisis).
- Notifications: composer with live previews (iOS lock screen, Android, web), targeting (all, topic subscribers, segment, language, platform, test devices), scheduling, rich image, deep link to content, history with sent/delivered/opened stats.
- Recommendations: all weights and rules from §9.8 editable, with a "preview feed as user X / as new guest" simulator and reset-to-defaults.
- Ads: §9.12.
- Integrations: one page per provider (§9.11) with form, masked secrets, "Test" button, test history.
- Analytics: §9.10.
- Logs: audit, auth, moderation, integration/provider, SMS delivery, push delivery, system errors (Sentry link), with search, filters, CSV export (export itself is audit-logged).
- Settings: site identity (name, logo, favicon, brand color), localization, SEO defaults, legal pages, security settings, feature flags.

Admin security (implement ALL)
- No public signup; invite-only with expiring single-use invite links.
- Mandatory MFA for every staff account: WebAuthn/passkeys (preferred) and TOTP as a fallback; recovery codes; MFA re-verification ("step-up auth") for sensitive actions (changing secrets, roles, bans, exports, deleting content).
- Passwords: argon2id, breach check (HIBP k-anonymity), minimum length 12, no composition theatre.
- Sessions: server-side sessions in httpOnly + Secure + SameSite=Strict cookies, CSRF protection, 15-min idle timeout and 12h absolute timeout (configurable), session bound to device fingerprint signals, list and revoke sessions, alerts on new device login.
- Optional IP allowlist (DB-configured, enforced at WAF and app level), geo-anomaly detection, brute-force protection with progressive delays and lockout.
- Four-eyes approval (second admin must approve) for: secret/integration changes in production, granting admin/super-admin roles, bulk deletion, ads activation. Configurable.
- Least privilege: object-level permission checks on every endpoint (deny by default), admin API on a separate host/path with its own throttles.
- Append-only audit log of EVERY staff action (who, what, before/after diff, IP, user agent, timestamp) with a hash chain (each entry hashes the previous one) so tampering is detectable; daily anchor of chain head to an S3 Object Lock (WORM) bucket.
- Strict CSP (nonce-based), HSTS preload, X-Frame-Options DENY, Referrer-Policy, Permissions-Policy, no inline scripts.
- Secrets are write-only in the UI (never sent back to the browser; shown masked as ••••last4).

# 9. BACKEND DOMAINS (Django apps)

accounts, auth_otp, social_auth, staff_security, rbac, taxonomy, content, editorial, media, youtube, live, engagement, moderation, notifications, recommendations, search, analytics, presence, audit, integrations, instagram_sync, ads, seo, site_config, feature_flags.

9.1 Identity & authentication (public users)
- Methods: phone + OTP (Beem SMS), Google (verify ID token server-side against configured client IDs), Apple (verify identity token, handle private relay email and revocation on account deletion). One user can link multiple methods; secure account linking.
- OTP: generated server-side (CSPRNG, 6 digits), stored hashed, 5-min TTL, max 5 attempts, resend cooldown 60s, per-phone/IP/device rate limits, all configurable. SMS template localized and includes the Android app hash.
- SMS PUMPING / TOLL FRAUD protection (critical): allowed country codes list, per-prefix velocity limits, global hourly SMS budget with alerting, Play Integrity (Android) and App Attest/DeviceCheck (iOS) attestation for OTP requests from apps, invisible challenge (e.g., Cloudflare Turnstile or reCAPTCHA Enterprise — configurable) on web.
- Tokens: short-lived access JWT (10 min) + rotating refresh tokens with reuse detection (reuse → revoke whole family). Mobile stores refresh in secure storage; web uses a Next.js BFF with httpOnly cookies (no tokens in JS).
- Guest device identity for personalization; merged on login.
- Account deletion (with grace period) and data export (PDPA Tanzania 2022 compliance), consent records with versions.

9.2 Roles & permissions (RBAC + scoping)
Roles: Super Admin, Admin, Editor-in-Chief, Section Editor, Journalist, Contributor, Moderator, Analyst (read-only), Verified User, User. Permissions are granular (e.g., content.publish, content.publish_direct, content.edit_others, live.go_live, live.moderate_chat, moderation.ban_user, integrations.manage, analytics.view, audit.view) and can be scoped to categories. Roles are DB-editable; system roles cannot be deleted. Journalists get go_live by default; other users get it only through an approved request.

9.3 Content & categories
- Content types: article, breaking, video, gallery, live_blog, live_stream, opinion, short, youtube, instagram_import. Common model + type-specific fields; body stored as versioned structured JSON blocks (schema-validated, sanitized with an allowlist — nh3 for any HTML; no raw HTML from clients).
- Editorial workflow: Draft → Submitted → In Review → Approved → Scheduled/Published → Unpublished/Archived, with permission-guarded transitions (state machine), comments between editor and journalist, and notifications on transitions. Journalists with content.publish_direct may publish directly.
- Revisions on every save; restore; diff.
- Taxonomy: hierarchical categories, tags, story clusters, regions (optional). Every post has exactly one primary category + optional secondary categories + tags.
- Slugs per language, redirect table on change.

9.4 Media pipeline — as in §3. Additional: idempotent processing, retries with backoff, dead-letter queue, per-asset processing status pushed to admin via WebSocket, orphan cleanup job, S3 lifecycle rules (originals → Intelligent-Tiering), CloudFront signed URLs available for future premium content.

9.5 YouTube — URL parser for all URL shapes, video ID validation, oEmbed metadata fetch (via an SSRF-safe HTTP client), thumbnail mirrored to S3, rendered as a lite facade on web/mobile, VideoObject schema on web.

9.6 Engagement & per-post policy
- Types: reactions/likes, comments, replies, bookmarks, shares (tracked), reposts/quotes, follow author, follow category, live chat, polls (block type).
- Policy resolution: post override → category default → global default; plus global kill switches. Comment modes: open, verified-users-only, pre-moderated (held for approval), closed. "Slow mode" (min seconds between comments per user) auto-enabled on hot posts (configurable threshold).
- Default global policy: likes ON, comments ON (open), bookmarks ON, shares ON, reposts OFF, live chat ON.
- API returns the resolved policy with every post so clients render only allowed actions; the server ALSO enforces it (never trust the client).

9.6.1 Engagement at massive scale (millions of simultaneous interactions)
- Likes/bookmarks: idempotent per (user, post). The API writes to Redis (membership + sharded counters for hot keys) and appends to a Redis Stream; Celery consumers batch-upsert into Postgres (unique constraint) and periodically reconcile counters. API responds immediately (optimistic).
- Counters shown to clients come from Redis; realtime counter updates are aggregated and broadcast at most every 1–2s per post per channel group (throttled fan-out), never per event.
- Comments: cursor pagination, write rate limits per user/IP, slow mode on hot posts, cached first page for anonymous reads.
- Anonymous read traffic (the vast majority) is served from CDN cache; personalized parts are fetched separately and small.
- Live chat at scale uses IVS Chat (not our WebSockets).
- Prove it with k6 load tests (§14).

9.7 Moderation (rule-based now; AI-ready interface, disabled)
- Rules engine (DB-configured): banned/flagged term lists per language with normalization (case, diacritics, leetspeak, repeated chars), link policy (block/allow domains, max links), spam heuristics (duplicate content, velocity, new-account limits), media rules, mention limits. Each rule has an action: allow, hold for review, hide, reject, plus severity.
- User reports with reason codes; auto-hide after N weighted reports (trust-weighted).
- Trust levels (new → regular → trusted) earned from account age and good standing; affect limits.
- Enforcement ladder: warn → mute (timed) → suspend (timed) → ban; strikes that expire; shadow-ban; IP/device ban for abuse. Users are notified with the reason and can appeal.
- A ModerationProvider interface exists with RuleBasedProvider implemented; AIProvider slot defined but disabled (no AI moderation in this build).
- Every moderation decision is logged (moderator, reason, before/after).

9.8 Recommendations — default settings (all DB-editable in admin, with versioning and reset to defaults)
- For You score = 0.35·freshness + 0.25·category/topic affinity + 0.20·engagement velocity + 0.10·editorial boost + 0.10·author affinity, then diversity re-ranking.
- Freshness: exponential decay, half-life 6h (news) / 48h (evergreen/features, flagged by editors).
- Engagement velocity: trending score = weighted engagements (view 1, like 3, comment 5, share 8, bookmark 4, completion of video ≥75% 4) over the last 2h, gravity-decayed (gravity 1.5).
- Affinity: user's interactions per category/author with 14-day decay; cold start uses onboarding topics + regional trending.
- Diversity: max 2 consecutive items from the same category, max 3 per author in the top 20, mix content types (at least 1 video in every 8 items if available).
- Breaking news pinned at top for 2h (configurable); editor "pin" slots on Home; already-seen items demoted; blocked/muted authors excluded; sensitive content respects user setting.
- "Latest" tab is pure reverse-chronological. Related articles: same story cluster > OpenSearch more_like_this + shared tags + same category, excluding the current article.
- Precomputed candidate pools in Redis sorted sets (refreshed every minute by Celery); per-user ranking at request time within a strict latency budget (p95 < 80ms).
- Simulator in admin to preview feeds.

9.9 Push notifications
- FCM HTTP v1 for Android, iOS (APNs via FCM) and web push. Service account JSON stored encrypted in DB config.
- Types: breaking news, followed topic/category, followed journalist published, journalist live, reply/mention to your comment, likes on your comment (batched digest, never one push per like), editorial picks, account/security.
- User preferences per type, quiet hours (default 22:00–07:00 Africa/Dar_es_Salaam, breaking can override if user allows), daily cap (default 6, configurable), language-aware content.
- Delivery: topic messaging for broadcasts (breaking to millions in < 2 minutes), batched per-user sends via Celery for personal notifications, collapse keys to replace stale updates, dedupe, TTL for time-sensitive alerts, invalid token cleanup.
- Rich notifications: image, action buttons (Read / Save), deep links into the exact screen; in-app notification center (bell) with unread badge via WebSocket.
- Tracking: sent, delivered (where available), opened, conversion; shown in admin.

9.10 Analytics, presence & time spent
- Client analytics SDK (Flutter + web) with batched, offline-queued events: app_open, session_start/end, screen_view, content_view, read_progress (25/50/75/100%), video_play/progress/complete, engagement events, search, push_open, live_join/leave, heartbeat. Event schema versioned and documented.
- Presence: heartbeat every 30s (WebSocket or HTTP fallback) → Redis sorted set with TTL; "online now" = active in last 60s, split logged-in vs guests, by platform.
- Admin analytics: online now (live list of logged-in users with current screen/content), users who opened today, DAU/WAU/MAU, new signups, sessions per user, average and total time spent, leaderboard of users by time spent (day/week/month), top content (views, read time, completion), top journalists, retention cohorts (D1/D7/D30), funnels (guest → signup → first engagement), traffic sources/referrers (web), device/OS/app version distribution, push performance, live stream analytics (peak/concurrent viewers, watch time).
- Per-user activity timeline (sessions, time spent, content viewed, engagements) for admins with analytics.view_users permission (access audited).
- Privacy: consent, IP truncation for analytics, retention controls, honor deletion requests across ClickHouse.

9.11 Database-driven configuration + "Test" buttons
- Only bootstrap values live in environment variables / Secrets Manager: DATABASE_URL, REDIS_URL, DJANGO_SECRET_KEY, KMS key ARN, environment name, allowed hosts. EVERYTHING else is in the database.
- IntegrationConfig model: provider, environment, versioned schema-validated fields, secrets encrypted with KMS envelope encryption (data key per record), status (draft / active / failing), last_tested_at, last_test_result. Configs cached in Redis and invalidated via pub/sub on change. Every change audit-logged; production changes require four-eyes approval (§8).
- Flow: Save as draft → Test → Activate. Activation of a config whose last test failed is blocked (Super Admin can override with a mandatory reason, logged).
- Every provider implements test() returning step-by-step results (step, pass/fail, latency, error detail, remediation hint), shown in the UI and stored in integration logs. Required tests:
  • AWS S3: put/get/delete a probe object; verify Block Public Access; CloudFront fetch of a probe file through OAC.
  • MediaConvert: endpoint/role/queue validation + optional tiny test job with a bundled 3-second sample.
  • Image processing: process a bundled sample, verify variants + blurhash.
  • AWS IVS: credentials check, create/describe/delete a temporary channel; IVS Chat room check.
  • Beem SMS: credentials + account balance check, sender ID configured, and "Send test SMS" to a number entered by the admin (delivery report shown when available).
  • FCM: validate service account, dry-run (validate_only) send, real test push to a registered admin test device.
  • Google Sign-In: validate client IDs (web/Android/iOS) format and discovery document reachability.
  • Apple Sign-In: validate key ID/team ID/service ID/private key by generating a client secret JWT and calling Apple's token endpoint validation.
  • Meta/Instagram: debug_token (validity, expiry, granted scopes), fetch IG Business account profile, fetch latest media item; report missing permissions precisely.
  • YouTube: oEmbed fetch of a known video.
  • Email (Amazon SES for staff invites/alerts): send test email.
  • OpenSearch, ClickHouse: connectivity + index/table existence.
  • Ads providers: config validation (IDs format) + test-mode ad request where supported.
- Message configuration is also DB-driven: SMS/push/email templates per language with variables, preview, and test send.

9.12 Ads (scaffolded now, OFF by default)
- Global ads switch (default OFF) + per-platform switches (web, Android, iOS) + per-placement config (home in-feed every N items, article mid-content after paragraph N, article end, video list) + per-category exclusions (e.g., no ads on tragedy/breaking stories) + frequency caps.
- Providers (pluggable, priority/waterfall order configurable): Google (AdMob for mobile, Google Ad Manager/AdSense for web), Meta Audience Network, AppLovin MAX.
- Consent: Google UMP / IAB TCF consent flow on mobile and web when ads are ON.
- When ads are OFF: SDKs are NOT initialized, no ad network requests, no reserved space, zero performance cost. Mobile SDKs are compiled in but initialized only from remote config.
- app-ads.txt and ads.txt served from DB config.

9.13 Instagram → platform sync (Meta)
- Config fields: Meta App ID, App Secret (encrypted), Facebook Page ID, Instagram Business/Creator Account ID, long-lived access token (encrypted) with automatic refresh before expiry and expiry alerts, Graph API version (pinned, editable), webhook verify token, sync interval (default 5 min), import mode (review queue — DEFAULT — or auto-publish), default category, hashtag → category/tag mapping rules, default engagement policy for imports, include/exclude media types (image, carousel, reel/video).
- Document the full Meta setup in /docs/runbooks/meta-instagram.md: create Meta app, add products, required permissions (verify current names, e.g., instagram_basic / instagram_business_basic, pages_show_list, pages_read_engagement, business_management), business verification, app review steps, token generation.
- Sync job polls the IG Graph API media endpoint (new items since last cursor), dedupes by IG media ID, DOWNLOADS media to S3 immediately (IG CDN URLs expire) and runs it through the normal pipeline (scan, transcode, variants), maps caption → title (first line, trimmed smartly) + body, carousel → gallery, reel/video → video/short, hashtags → tags via mapping, preserves permalink as source attribution.
- Also subscribe to available Meta webhooks (e.g., comments/mentions) where useful, verified with the App Secret signature.
- "Test" = token debug + fetch latest post + dry-run mapping preview showing exactly how it would appear on the platform.
- Imported items appear in the admin review queue with an "Imported from Instagram" badge.

9.14 Logging & audit
Structured JSON logs (request ID/trace ID correlation across services), audit log (§8), auth log (logins, OTP requests/verifications, failures, lockouts), moderation log, integration log (every external call: provider, endpoint, status, latency, redacted payload), SMS log (with delivery status callbacks), push log, job log (Celery task outcomes). PII and secrets redacted at the logger level. All browsable in admin with filters; retention configurable.

# 10. SECURITY (WHOLE PLATFORM)

- Target OWASP ASVS Level 2 for public surfaces and Level 3-style controls for admin. Threat model documented in /docs/security/threat-model.md (STRIDE per component).
- Django hardening: SECURE_* settings, HSTS, secure cookies, CSRF, strict ALLOWED_HOSTS, no DEBUG in non-dev, custom user model, argon2.
- Rate limiting at WAF (per IP) and app level (per user/device/endpoint), with stricter limits on auth, OTP, comments, uploads, search.
- Input validation via serializers + JSON-schema for content blocks; output encoding; sanitize rich text; SSRF-safe HTTP client (block private IP ranges, metadata endpoints) for oEmbed/link previews/Instagram fetches.
- Uploads: size/type limits, magic-byte validation, malware scan, EXIF stripping, randomized keys, never executed or served from the API domain.
- IAM least privilege per service; S3 bucket policies; KMS for secrets; Secrets Manager rotation for bootstrap secrets; VPC private subnets for DB/Redis; security groups minimal.
- Supply chain: Dependabot/Renovate, pip-audit, npm audit, osv-scanner, Bandit, Semgrep, Trivy container scans, gitleaks — all in CI, blocking on high/critical.
- Mobile: certificate pinning (with backup pins and remote kill-switch), root/jailbreak signals (soft), obfuscation, no secrets in the app binary, Play Integrity/App Attest.
- Webhooks (MediaConvert/EventBridge, Meta, Beem delivery reports, revalidation): signature verification + replay protection.
- Security headers + CSP on web and admin. Regular backup + restore drill documented.

# 11. PERFORMANCE & SCALE TARGETS

- API: p95 < 150ms for cached reads, p95 < 300ms for writes; zero N+1 queries (enforced with query-count assertions in tests); cursor pagination everywhere; ETag/If-None-Match; gzip/br; select_related/prefetch_related discipline; covering indexes reviewed with EXPLAIN for hot queries.
- Caching layers: CDN (anonymous pages and public API GETs with surrogate keys/purge on publish) → Redis (objects, feeds, counters) → Postgres.
- Horizontal scaling: stateless API, autoscaling on CPU + request count; Celery autoscaling on queue depth; WebSocket tier scaled separately.
- Capacity targets proven by load tests (§14): 20k RPS of mixed anonymous reads at origin+CDN with < 1% errors; 5k likes/sec on a single hot post with correct final counts; 100k concurrent viewers on a live stream (IVS) with chat; breaking-news push to 1M devices in < 2 minutes.
- Resilience: circuit breakers and timeouts on every external call, graceful degradation (if recommendations fail → Latest feed; if analytics ingest fails → drop with metric, never block the user), health/readiness probes, DB PITR backups (RPO ≤ 5 min, RTO ≤ 1h documented).

# 12. LOCALIZATION

Kiswahili (default) and English for all UI strings (ARB files in Flutter, next-intl on web/admin), localized dates/numbers, content can have sw and/or en versions linked as translations (hreflang). Timezone default Africa/Dar_es_Salaam. No hardcoded strings.

# 13. OBSERVABILITY & OPS

OpenTelemetry traces across web → API → Celery → external providers; dashboards (latency, error rate, queue depth, cache hit ratio, DB load, SMS spend, push throughput, transcoding backlog); alerts to on-call (SMS budget spike, OTP failure spike, integration failing, error-rate SLO burn, token expiry in < 7 days). Runbooks for each alert in /docs/runbooks/. Status of every integration visible on the admin dashboard.

# 14. TESTING & QUALITY GATES (CI must enforce)

- Backend: pytest + factory_boy; ≥ 85% coverage on domain/services; tests for every permission rule, state transition, engagement policy resolution, rate limit, OTP flow, moderation rule, recommendation scoring; query-count tests on list endpoints; provider tests with recorded fixtures (and live "smoke" tests runnable against staging).
- Contract: OpenAPI schema diff check; generated clients up to date.
- Web/Admin: unit (Vitest), component tests, Playwright E2E (guest browsing, intent-resume login, publish flow, moderation flow, integration test buttons), axe accessibility checks, Lighthouse CI budgets, skeleton-vs-content layout tests.
- Mobile: unit, widget, golden tests (light/dark, sw/en, skeleton/loaded), integration tests (onboarding, guest browse, OTP login, like/comment/bookmark, video playback, deep links), performance profiling notes.
- Load: k6 scenarios for §11 targets, results committed to /docs/perf/.
- Security: automated scans (§10) + an OWASP ZAP baseline scan against staging.

# 15. MILESTONES (each ends with green CI + updated docs + demo notes in PROGRESS.md)

M0 Foundation — monorepo, tooling, CI/CD, Terraform base (VPC, RDS, Redis, S3, CloudFront, ECS, WAF), design tokens package, Django skeleton with custom user, RBAC, audit log, site_config + integrations framework (encrypted config, Test button framework), OpenAPI + client generation.
  Acceptance: deploys to staging from CI; admin can log in with mandatory passkey/TOTP; audit hash chain verifiable; S3 integration Test button passes against real AWS.

M1 Content core — taxonomy, content types, block JSON schema, editorial workflow, revisions, media pipeline (upload → scan → image variants / MediaConvert HLS), YouTube import, admin editor + media library.
  Acceptance: a journalist uploads a 1GB video and it plays as adaptive HLS on web; image variants + blurhash generated; EXIF removed; YouTube URL in every form embeds correctly; workflow permissions enforced by tests.

M2 Public website — all pages, SEO requirements, ISR + revalidation, skeletons, dark mode, i18n.
  Acceptance: Lighthouse CI budgets pass; Rich Results Test validates NewsArticle/LiveBlogPosting/VideoObject on staging; news sitemap valid; skeleton layout tests pass.

M3 Mobile app — onboarding, 5-tab navigation, feeds, native article renderer, video + shorts, search, saved/offline, settings, deep links, skeletons, dark mode, i18n.
  Acceptance: golden tests pass; cold start and 60fps targets met on a documented mid-range Android device; visual consistency checklist web ↔ mobile signed off in /docs/design/consistency.md.

M4 Identity & engagement — phone OTP via Beem (with fraud controls), Google, Apple, account linking, intent-resume gating, engagement types + policy resolution + kill switches, scalable counters, comments (IG-style), follows, reposts, bookmarks.
  Acceptance: Beem Test button sends a real SMS; OTP autofill works on Android and iOS; 5k likes/sec load test passes with exact final counts; disabled engagement types never render and are rejected server-side.

M5 Moderation & users — rules engine, reports, queue, enforcement ladder, appeals, user management, trust levels.
  Acceptance: every rule type covered by tests; moderator actions logged and reversible; banned user cannot engage on any platform within 5 seconds of ban.

M6 Notifications — FCM mobile + web push, preferences, quiet hours, caps, composer with previews, breaking alerts, in-app notification center, delivery analytics.
  Acceptance: FCM Test button delivers to a test device; topic broadcast load test meets the 1M-in-2-minutes target (simulated); deep links open the right screen from killed state.

M7 Live — IVS channels, mobile go-live (native SDK wrapper), RTMPS/OBS, viewer with IVS chat, recording → VOD, go-live permission requests, live notifications, live analytics.
  Acceptance: journalist goes live from the phone, viewers on web + mobile watch with < 5s latency, chat moderated, recording auto-published as VOD.

M8 Recommendations & search — candidate pools, scoring with defaults, diversity, simulator, OpenSearch with sw/en analyzers, related content.
  Acceptance: scoring unit-tested against fixtures; simulator shows expected ordering; p95 feed latency < 80ms under load.

M9 Analytics, presence & logs — SDKs, ingest pipeline, ClickHouse, realtime presence, all admin analytics views, all log viewers.
  Acceptance: online-now count accurate within 60s; time-spent leaderboard correct against seeded data; retention/funnel numbers verified with fixtures.

M10 Meta/Instagram sync + Ads scaffolding — full IG sync per §9.13, Ads config per §9.12 (OFF by default), consent flows.
  Acceptance: Instagram Test button shows token validity + latest post + mapping preview; a new IG post appears in the review queue within the sync interval with media mirrored to S3; with ads OFF there are zero ad network requests (verified by test).

M11 Hardening & launch readiness — full security review (threat model, ZAP, dependency audit), load test suite for all §11 targets, backup/restore drill, runbooks, store-readiness (privacy labels, data safety form notes, account deletion, screenshots guidance), final docs.
  Acceptance: all §11 targets met and documented; no high/critical findings open; launch checklist complete.

# 16. DEFINITION OF DONE (for every feature)

Implemented end-to-end on every relevant surface (API + admin + web + mobile), permission-checked server-side, audit/log events emitted, skeleton states matching content, empty/error/offline states designed, localized sw/en, light/dark verified, accessible, tested (unit + integration/E2E where applicable), documented (API docs + user-facing admin help text), and performance-checked against budgets.

Begin with M0. First output: the ADR list you will write, the finalized repository structure, and the M0 task breakdown. Then execute.
