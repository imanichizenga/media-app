# Website

The readers' site: Next.js (App Router, Server Components), port 3000. How it renders, caches and moves: [ADR-0046](../support/docs/adr/0046-website-rendering.md). Where it runs: [ADR-0047](../support/docs/adr/0047-website-hosting.md).

| Folder | What |
|---|---|
| `app/[locale]` | Pages. Swahili has no prefix: `proxy.ts` adds it |
| `app/document` | Sends a page without the framework's client runtime |
| `app/*` | Machine addresses: sitemaps, feeds, share images, app links, revalidation |
| `components` | What is drawn. Cards, skeletons and the article renderer are in `support/packages/ui` |
| `islands` | What is pressed: plain TypeScript, bundled into `public/js` |
| `lib` | The API, the cache's tags, SEO, the policy |

```sh
cd backend && API_SURFACE=public … uvicorn config.asgi:application --port 8010   # filled by seed_demo
pnpm --filter @news/web dev                         # with the framework's client, for hot reload
API_PROXY_TARGET=http://127.0.0.1:8010 pnpm --filter @news/web build   # as readers get it
pnpm --filter @news/web test
pnpm --filter @news/e2e web                         # end to end; starts everything itself
```

| Variable | |
|---|---|
| `API_BASE_URL` | The public API |
| `SITE_URL` | Readers' own address |
| `MEDIA_ORIGIN` | Where pictures and video come from (policy) |
| `REDIS_URL` | The shared data cache and single-use numbers |
| `REVALIDATE_SECRET` | The same as in Admin → Integrations → Website and CDN |
| `SITE_CLOSED=1` | Not to be indexed |
| `API_PROXY_TARGET` (build), `WEB_LOCAL=1` | Local and tests only |

In production the site does not start without `API_BASE_URL`, `SITE_URL`, `REDIS_URL` and `REVALIDATE_SECRET`: nothing is made up.
