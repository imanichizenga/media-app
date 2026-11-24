# 0018. Admin CSP and data fetching

Status: accepted, 2026-11-23

## Context
XSS in admin is the worst case.

## Decision
Per-request nonce, `strict-dynamic`, no `unsafe-*`, Trusted Types with one policy that admits only our own bundles. Pages contain no data; the browser fetches it, because a server-side fetch would change the client fingerprint. The CSRF token is in memory only. Theme and language come from cookies, so no inline script is needed.

## Alternatives
SRI-only CSP; a BFF holding sessions.

## Consequences
Every page is dynamic. E2E fails on any CSP violation.
