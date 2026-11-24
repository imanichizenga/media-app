# 0036. Repository layout

Status: accepted, 2026-11-24

## Context
The client asked for a repository a newcomer understands: backend, admin, website, mobile, and one place for everything else.

## Decision
`backend`, `admin`, `web`, `mobile`, `support`. Inside support: docs, packages, generated (API clients), tests, design, infra, scripts. Files tools look for at the top stay there. Replaces the layout in SPEC §4 and ADR-0001.

## Alternatives
`apps/` and `packages/` at the top.

## Consequences
Older text naming `apps/api` or `docs` reads `backend` and `support/docs`; the README says so.
