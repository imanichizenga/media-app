# 0008. Audit hash chain

Status: accepted, 2026-11-23

## Context
Tampering must be detectable.

## Decision
SHA-256 over canonical JSON plus the previous hash, serialised by a row lock, written in the same transaction as the change. Triggers reject UPDATE, DELETE and TRUNCATE; the runtime DB role lacks those grants. The head is copied daily to S3 Object Lock (COMPLIANCE).

## Alternatives
QLDB (discontinued); HMAC chain (not independently verifiable).

## Consequences
Staff writes serialise on one row (tens per second is ample). Someone who rewrites the entire database is caught by the WORM copies. Entries since the last anchor are protected by the DB controls only.
