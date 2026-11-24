# 0034. Compact counts in Swahili

Status: accepted, 2026-11-24

## Context
Counts are compact everywhere. CLDR short form for Swahili is "elfu 1.3", twice as wide as "1.3K", and only below a million.

## Decision
The same letters in both languages: 1.3K, 3.4M, 1.2B, formatted by `Intl` compact notation. Accessibility labels carry the exact number in the reader's locale.

## Alternatives
CLDR Swahili; words ("maelfu").

## Consequences
A native editor confirms it (review list). One function to change if they disagree.
