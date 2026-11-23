# 0001. Monorepo tooling

Status: accepted, 2026-11-23

## Context
Four products share one contract and one design system.

## Decision
pnpm workspaces + Turborepo for JS, uv for Python, Dart packages under `packages/`. App shells are created in the milestone that fills them.

## Alternatives
Nx; Bazel; separate repositories.

## Consequences
One PR can change API, client and UI together. `apps/web` and `apps/mobile` do not exist before M2 and M3.
