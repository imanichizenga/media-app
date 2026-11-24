# 0027. One content schema

Status: accepted, 2026-11-24

## Decision
`support/packages/content-schema/schema/content.v1.json` defines article bodies. TypeScript types, Zod validators and Dart models are generated from it, CI refuses a stale copy, and the API validates against the same file. Writers are strict; readers ignore unknown fields and replace an unknown block with a calm fallback. Text is marks on runs, never HTML. Links allow `https`, `http`, `mailto` and site paths, and refuse everything a browser would read as another site (`//`, `/\`, control characters). `support/docs/content-fixtures` holds valid and invalid documents; Python, TypeScript, Dart, the editor's round trip and each renderer must agree on all of them.

Changes within version 1 are additive. A breaking change is a new version with a migration of stored bodies.

Zod is told never to compile with `eval`, before any schema is built: the admin's Trusted Types policy reports even the attempt.

## Alternatives
HTML with sanitising (two renderers would disagree, and every sanitiser bug is an XSS); Portable Text or Slate JSON (no generated Dart models, looser validation).
