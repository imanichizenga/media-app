# 0040. Offline first

Status: accepted, 2026-11-24

## Context
News must be there before the network is.

## Decision
A dio interceptor keeps every GET answer in drift with its ETag. Screens read it first and refresh behind it; a failure keeps what is shown and says how old it is. A story type from the future is dropped from lists instead of failing them; an answer in an older shape counts as no answer. Saved articles are whole: text and pictures, in a store nothing evicts; what failed is taken up at the next start. Cache: 24 MB, 30 days, oldest first. Pictures: 600 files, 30 days; 96 MB in memory.

## Alternatives
Per-screen tables (a second schema to migrate); http_cache files.

## Consequences
The whole API is cached by one class. A kill switch or theme change is known from the last answer even without a network.
