# 0013. API contract and clients

Status: accepted, 2026-11-23

## Context
Generated clients must never be stale.

## Decision
drf-spectacular → OpenAPI 3.1 committed in `docs/api`. `openapi-typescript` + `openapi-fetch` for TS; `openapi-generator` dart-dio for Dart. CI regenerates and diffs. Tests validate real responses against the schema. Errors are RFC 9457 with stable codes. Lists return an opaque `next_cursor`.

## Alternatives
GraphQL; hand-written clients.

## Consequences
Conformance tests found two contract bugs during M0.
