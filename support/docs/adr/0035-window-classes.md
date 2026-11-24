# 0035. Window classes

Status: accepted, 2026-11-24

## Context
Tablets and foldables (D7).

## Decision
Compact below 600, medium 600 to 839, expanded from 840 (Material window classes). Medium: two-column feed, article capped at 680. Expanded: navigation rail instead of the bottom bar, more columns, related stories beside the article. The website keeps its own breakpoint at 1024.

## Alternatives
Scale the phone layout; a separate tablet app.

## Consequences
Prototyped for Home and Article at 768 and 1024; goldens at compact and expanded widths in M3.
