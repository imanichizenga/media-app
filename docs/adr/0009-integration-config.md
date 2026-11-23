# 0009. Integration configuration

Status: accepted, 2026-11-23

## Context
Everything configurable in the DB, with tests.

## Decision
Immutable versions; a test result belongs to one exact version. Fields are a typed Pydantic model that also drives the admin form. Secrets are envelope-encrypted (AES-256-GCM, a KMS data key per record) and bound to their record by encryption context. Plaintext lives in process memory only; Redis pub/sub carries invalidations, with a 60s TTL as a backstop.

## Alternatives
Secrets Manager per integration; plaintext in Redis.

## Consequences
Activation requires the latest test of that version to pass. An emulator can never pass the S3 test.
