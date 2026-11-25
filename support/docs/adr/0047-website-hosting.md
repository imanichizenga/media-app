# 0047. The website runs on ECS behind CloudFront

Status: accepted, 2026-11-25.

## Context
Vercel, or the account that runs everything else.

## Decision
ECS Fargate behind CloudFront, in the platform module (`web.tf`): one account, one purge path (the worker that purges the API's distribution purges this one with the same call), the same WAF, deploys, alarms and rollback.

- Its own CloudFront distribution. Cookies and unknown query parameters are in neither the cache key nor the request to the origin. Only `/api/*` takes a POST, uncached.
- It shares the API's internal load balancer, by host name; `/theme/*` goes to the API.
- It reads the API inside the network (a private DNS zone for the API's host, the same certificate), never through the API's CDN, where an answer may be a second older than the purge.
- A Redis of its own, not a cluster, and two secrets of its own. No AWS permissions.
- Only production may be indexed (`SITE_CLOSED`).
- `www.` redirects at the edge.

## Alternatives
Vercel: less to run, but a second vendor with the readers' traffic, a second purge path, a second bill that grows with traffic, and no edge in our WAF. OpenNext on Lambda: cold starts on a news site.

## Consequences
**Never run against AWS yet:** plan-tested only. After the first apply, `REVALIDATE_SECRET` is copied once from Secrets Manager into Admin → Integrations → Website and CDN (first-deploy, step 8).
