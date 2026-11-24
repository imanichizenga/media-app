# 0026. Public read API and caching

Status: accepted, 2026-11-24

## Decision
Public content endpoints take no cookies and know no user, so one response serves everyone. Every response has an ETag, `s-maxage`, `stale-while-revalidate=600`, `stale-if-error=86400` and surrogate keys (`post-`, `category-`, `author-`, `tag-`, `story-`, `latest`, `navigation`). A 404 is kept for 30 seconds. Cursors are opaque positions (time and identifier), so a page never repeats or skips when news arrives. Anything about a person is a separate, small endpoint (M4).

Publishing queues one message on `critical`: a signed call to the website's revalidation webhook, and a CDN purge. CloudFront cannot purge by key, so the purge translates keys to paths, with one wildcard for the API's lists. Breaking news does not wait for the purge: the API's own lists live 60 to 120 seconds at the edge.

## Alternatives
Fastly or Cloudflare (purge by key, but another vendor in front of AWS origins); GraphQL (POST, hard to cache at the edge).

## Consequences
If the purge fails it retries; meanwhile readers see at most `s-maxage` of delay. Query-count tests on every list keep the origin cheap when the cache is cold.
