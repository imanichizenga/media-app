# 0020. Realtime deployment and staff sockets

Status: accepted, 2026-11-23

## Context
Staff need live progress (integration tests now, media processing in M1). Sockets bypass CORS and CSRF tokens, stay open for hours, and Chromium does not send `Sec-CH-UA-*` on the handshake, so the HTTP fingerprint check would end valid sessions.

## Decision
- A separate process (`config.asgi_realtime`, surface `realtime`): sockets and health checks, no API routes, its own scaling and no AWS permissions. Uvicorn, one process per task, 4 KB message limit.
- **Signals, not data.** A message names what changed; the client refetches through REST, where permissions and schemas already live. Publishing happens after commit, and a lost signal only costs freshness because clients also poll slowly.
- **Admission:** exact Origin, IP allowlist, session cookie (read only). Then a single-use 30-second ticket as the first message, issued by the authenticated, CSRF-protected, fingerprint-checked REST API and bound to that session. It is never in the URL.
- **Revalidation** every 10 seconds: session, account, allowlist and permissions. An open socket does not keep a session alive.
- Channel layer: Redis pub/sub on the non-cluster broker group (ADR-0014). Readiness fails without it.

## Alternatives
Cookie alone (a stolen cookie would skip the device check); ticket in the query string (logged by proxies); data in messages (a second permission system); SSE (needs a connection per stream); Daphne.

## Consequences
CloudFront VPC origins carry WebSockets since May 2026. Public sockets (M4 counters) are a separate consumer and will need their own Redis group: broker load must not depend on readers.
