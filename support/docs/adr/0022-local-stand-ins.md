# 0022. Local stand-ins for cloud services

Status: accepted, 2026-11-23

## Context
Every provider needs a local stand-in. The obvious choices changed: MinIO is no longer published on Docker Hub, and LocalStack (2026.10) exits with "valid license required" without an account.

## Decision
- **Object storage:** SeaweedFS (Apache-2.0). `tests/live_storage.py` is the contract: presigned multipart, listing finished parts after a cut, byte-identical resume, range reads, refusal of anonymous and tampered requests, deletion.
- **AWS control plane** (KMS, SES, STS, WAF, CloudFront, CloudWatch): moto, as before.
- **Search, analytics, mail, traces:** the real OpenSearch, ClickHouse (LTS), Mailpit and OpenTelemetry collector.
- Compose profiles, so a developer starts only what the task needs. All ports bind to loopback.
- Fakes are refused in staging and prod by a system check (`AWS_ENDPOINT_URL`, `LOCAL_ENCRYPTION_KEY`). Each new fake adds its own check.

## Alternatives
MinIO from another registry (unclear provenance and updates); LocalStack with an account (a secret for every developer and CI run); Garage (no ListParts guarantees were verified); moto for storage (keeps uploads in memory).

## Consequences
Two endpoints instead of one: M1 adds a storage-only endpoint setting, with its own system check, when the media pipeline needs it.
