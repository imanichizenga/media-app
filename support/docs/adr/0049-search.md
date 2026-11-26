# 0049. Search: OpenSearch for readers, Postgres when it is down

Status: accepted, 2026-11-26. Brings forward the search half of M8 (SPEC: "OpenSearch, Swahili + English analyzers,
typo tolerance"); recommendations stay in M8.

## Context

Until now the public search endpoint answered `available: false` and nothing else; the website's magnifier opened the
Explore page and the app had no field at all. Readers expect to find a story by a word of its headline, a place, a
person or a writer, in Swahili or English, with typing mistakes, from the first letters, newest stories first when
the words match equally. The archive grows by thousands of stories a month and must stay fast at millions.

## Decision

**Engine.** Amazon OpenSearch Service, version **3.7** (the newest AWS runs, 2026-07), the same version in CI (service
container) and production. One index per language behind an alias (`news-sw` → `news-sw-<version>`), so mappings
change by building a new index and swapping the alias, never in place.

**What is indexed.** Every `Publication` (the reader's copy of a story, one per language): headline, standfirst, the
text of the body blocks, tags, writers, category and its parents, regions, type, published and modified times, the
etag, and the card readers see (stored, not indexed), so a search answers without touching the database. The body is
indexed but not stored. Document id: the post's id, in its language's index.

**Analysis.**
- Swahili: OpenSearch has no Swahili stemmer, so lowercase, ASCII folding and a Swahili stop list; partial words are
  found by an edge n-gram field (2 to 15 letters) on the headline, which also serves the suggestions.
- English: the `english` analyzer (stemming, possessives, stop words), plus the same edge n-gram field.

**Ranking.** `multi_match` over headline (×4), standfirst, tags and writers (×2), category (×1.5) and body (×1), with
`fuzziness: AUTO` (one or two typing mistakes depending on the word's length, never on the first letter) and a phrase
match on the headline that lifts exact phrases. Then recency: a Gaussian decay on the publication time (half the
weight after 30 days) added to a constant, so a new story wins a tie but an old story that matches far better still
comes first. Readers can choose "newest" instead. Filters: type, category (with its children), date range. Only
what is published and due (`published_at ≤ now`) is ever returned.

**Pages.** `search_after` with an opaque cursor (score, time, id), 20 a page, at most 50 pages: no deep `from`, which
costs more with every page at millions of documents. The highlight comes back as segments
(`[{text, hit}]`), not HTML, so neither client renders markup from the engine.

**Suggestions.** `GET /content/search/suggest?q=`: up to 6 headlines from the n-gram field (and fuzzy), for
search-as-you-type. Both answers are cached by the CDN for 60 s on the normalised query (lower case, spaces
collapsed, 1 to 100 characters); search is rate limited like the other public reads.

**Indexing.** The publishing code already calls `changed()` after every publish, refresh and withdrawal; it now also
queues `search.index_post(post_id)` after commit. The task reads the post's current publications under a per-post
lock and writes or deletes them, so it is idempotent and a late task never writes old text. Retries with backoff while
the engine is unreachable. `reconcile` (Celery beat, hourly, and a command) compares ids and etags between the
database and each index, a month of publications at a time, and repairs what differs. `search_reindex` builds a new
index with bulk requests (500 documents each), swaps the alias, reconciles what changed meanwhile, and deletes the
old index.

**When the engine is down.** A circuit breaker (3 failures in 30 s opens it for 30 s; 1.5 s timeout per request)
sends searches to Postgres: a weighted `tsvector` on each publication (headline A, standfirst and tags B, body C;
`english` or `simple` configuration by language) with a GIN index, and a trigram index on the headline for typing
mistakes. Answers say `engine: "fallback"`; clients show them the same way. This is a real engine, not a stand-in:
locally and in tests without `OPENSEARCH_URL` it is the engine. In staging and production `OPENSEARCH_URL` is
required (the settings refuse to start without it), so the fallback is only ever a fallback there.

**Capacity.** A story is about 10 KB indexed. Per language: 2 primary shards up to ~5 million stories, 1 replica,
3 data nodes across 3 zones (`r7g.large.search`), `refresh_interval` 5 s. Measured, not assumed: `search_load`
fills an index with synthetic stories and reports p50/p95 of real queries (support/docs/perf/search.md).

## Alternatives

- **Postgres full text only.** No Swahili analysis, weak typing-mistake tolerance (trigrams on short fields only),
  ranking that is hard to tune, and search load on the primary database. Kept as the fallback.
- **Typesense / Meilisearch.** Very good typo tolerance, but not a managed AWS service in our region and a second
  thing to operate; the SPEC already chose OpenSearch, which M8's "more like this" also needs.
- **Writing to OpenSearch inside the publishing transaction.** A slow engine would slow publishing, and a rolled-back
  transaction would leave the index ahead of the database.

## Consequences

- Search works on the website (a server-rendered form that works without JavaScript, suggestions from a small island)
  and in the app (a native search field on Explore, debounced suggestions, filters, recent searches on the phone).
- A new AWS resource (A1–A3 must exist first): OpenSearch domain in the VPC, IAM-signed requests (SigV4), encrypted
  at rest and in transit, in Terraform with plan tests. Its cost is in the human-actions runbook.
- Synonyms an editor can change (e.g. "Dar" → "Dar es Salaam") and "did you mean" are the next steps (M8).
