# 0030. Three themes as data

Status: accepted, 2026-11-24

## Context
Three curated looks, each light and dark, selectable in the admin, for web, admin and app.

## Decision
`packages/design-tokens/src/themes.json` holds neutrals per theme and scheme, and rules that derive the brand tokens. Core tokens (space, radius, type, motion) stay fixed. The generator writes the bundled default (CSS, Tailwind, Dart) and the API's copy. Widgets and components see token names only. A colour is valid only if every pair passes in **all** themes and both schemes, so changing theme can never fail.

## Alternatives
Free-form colour fields per token (no guarantee of contrast or taste); one theme per build.

## Consequences
A fourth theme is a JSON entry. `accent` became `brand`, `brand-text`, `link`, `liked` and friends; `tokens.js` is gone, TypeScript imports `@news/design-tokens/theme`.
