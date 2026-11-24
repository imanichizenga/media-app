# 0012. Design tokens

Status: accepted, 2026-11-23; colour rules replaced by ADR-0029 and ADR-0030

## Context
One look across web, admin and mobile.

## Decision
DTCG JSON → CSS variables, a Tailwind 4 theme, JS and a Flutter ThemeExtension. The Tailwind palette is reset, so only tokens can be used. 97 contrast checks run in CI. `danger` is rust, not red: red means breaking or live.

## Alternatives
Figma Tokens; hand-written themes.

## Consequences
A colour that fails AA cannot be merged. Admin branding also enforces AA for accents.
