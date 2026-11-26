# 0038. Mobile architecture

Status: accepted, 2026-11-24

## Context
One app, offline first, built against the contract.

## Decision
`lib/app` (bootstrap, router, shell), `lib/core` (network, storage, config, formats, telemetry), `lib/ui` (tokens, components, states), `lib/features/*`. `core` never imports a screen, `ui` never imports a feature (a test enforces it). Riverpod 3 with generated providers; screens watch `AsyncValue`; no mutable singletons. The generated API client **is** the domain model: it already carries the contract, and a second set of classes would only drift. A feature holds its notifiers and screens side by side; repositories exist where there is behaviour to hold (`Library`, `Feed`, `CachedFirst`), not as a layer of pass-throughs.

## Alternatives
Freezed domain classes mapped from the client; a folder per layer per feature as in the task text.

## Consequences
Fewer files, one source of truth. If a screen ever needs a shape the API does not have, it gets its own class then. freezed and json_serializable are not used in the app.
