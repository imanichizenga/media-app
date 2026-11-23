# 0005. Staff sessions

Status: accepted, 2026-11-23

## Context
Requirements: httpOnly, Strict, idle and absolute timeouts, revocation, device binding.

## Decision
Opaque 256-bit tokens, stored as SHA-256 in PostgreSQL. `__Host-` cookie, SameSite=Strict. The token rotates when MFA completes. CSRF = HMAC of the session token, plus an exact Origin check. The fingerprint is coarse (browser family, OS) so updates do not sign people out.

## Alternatives
JWT (no immediate revocation); Redis sessions (eviction signs people out).

## Consequences
One indexed read per request. Rotating DJANGO_SECRET_KEY invalidates CSRF tokens and recovery codes (runbook).
