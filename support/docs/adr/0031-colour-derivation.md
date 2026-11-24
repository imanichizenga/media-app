# 0031. One derivation, three ports, shared vectors

Status: accepted, 2026-11-24

## Context
One colour must become the same theme in Python (validation), TypeScript (preview, web) and Dart (app).

## Decision
OKLCH, specified in `packages/design-tokens/spec/derivation.md`. Hue is a unit vector, not an angle: no trigonometry, so nothing for platforms to disagree about. Walks count steps instead of accumulating. Results are rounded to 8 bits before contrast is judged. `vectors.json` (80 colours in six theme-schemes, 300 raw paints, stylesheet digests) runs in all three ports in CI; one differing digit fails. Dark surfaces get two reds: a fill that carries white text, and a lighter, softer one for text and icons.

## Alternatives
HSL (uneven lightness); Material colour utilities (no Python port, different goals); server-only derivation (no live preview, no offline app).

## Consequences
Changing a rule means changing three files and regenerating vectors on purpose. Any hue has a valid neighbour (property-tested).
