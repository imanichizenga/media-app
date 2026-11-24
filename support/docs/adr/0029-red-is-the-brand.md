# 0029. Red is the brand; signals are shapes

Status: accepted, 2026-11-24

## Context
The client chose white, red and black, red dominant (G6). Until now red meant breaking or live and nothing else (SPEC §5, ADR-0012). The brand colour can now equal the signal colour. This replaces that rule.

## Decision
Red appears only on: the wordmark, the masthead accent, the active place, primary buttons, article links, the liked heart, and breaking and live signals. Everything else is ink. Signals are told apart by **shape** (WCAG 1.4.1): breaking is a full-width banner with an icon and an uppercase label; live is a filled pill with a dot, and a ring in the live rail. Nothing else may use those shapes. The live dot is the only thing that moves by itself. Destructive buttons are outlined, because a filled rust button beside a filled red one would differ by hue alone. Focus rings are ink.

## Alternatives
Keep a second accent colour; colour-code categories.

## Consequences
The gallery review counts red: no screen may read as a red screen. A client may choose another hue and every rule still holds. The live rail lost its pill: ring and spoken label say it, and four pills in a row were four red things.
