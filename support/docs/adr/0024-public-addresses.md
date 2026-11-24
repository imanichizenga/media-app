# 0024. Public addresses

Status: accepted, 2026-11-24

## Decision
`/{category}/{slug}` in Swahili, the default language, and `/en/{category}/{slug}` in English. Each language has its own slugs. Only `seo/paths.py` builds addresses, and it reserves every first segment the website uses. A changed slug or category writes a redirect in the same transaction; chains are flattened, and a loop is refused. The website asks `/content/resolve` before it answers 404.

## Alternatives
Identifiers in addresses (never break, but read badly in print and on air); dates in addresses (age a story that is still true).

## Consequences
Moving a category rewrites addresses in its whole branch. That runs in the background, and old addresses work throughout.
