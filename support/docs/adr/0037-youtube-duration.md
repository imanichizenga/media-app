# 0037. Video cards always say how long

Status: accepted, 2026-11-24

## Context
Every video card shows a duration (D2). YouTube oEmbed does not return one, and its Data API needs a key.

## Decision
Editors type the length of a YouTube video; it is required to publish. Cards carry `duration_ms` wherever the video lives.

## Alternatives
YouTube Data API key; scraping the watch page.

## Consequences
A little typing. Posts published before keep no badge until edited.
