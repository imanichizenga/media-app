# 0046. How the website renders, caches and moves

Status: accepted, 2026-11-25. **Amended 2026-11-26**: no nonce (see "The policy").

## Context
The specification asks for App Router and React Server Components, ISR, a strict nonce policy, CDN caching, an app-like feel with skeletons, and at most 120 KB of script on an article. Two of these pull apart:

- Streaming with `loading.tsx` answers 200 before a page knows it is a 404 or has moved.
- The App Router's client runtime alone is about 138 KB gzipped (Next 16.4, measured with both bundlers), before a line of ours.

## Decision

**Server Components on the server, documents to readers.** Every page is an App Router page made of Server Components. `app/document` asks for it and sends it without the framework's client scripts and without the second copy of its data (`lib/slim.ts`). What is pressed (theme, text size, save, share, video, shorts) is done by `web/islands`, plain TypeScript bundled by esbuild: **under 6 KB** instead of 145; the HTML of Home went from 32 to 13 KB. The video player (hls.js) is fetched when a video is asked for.

**Revalidation is of data.** Answers of the API are kept in the Next data cache, tagged, in a Redis shared by all instances (`cache-handler.mjs`). `POST /api/revalidate` (HMAC over time and body, five minutes, each id once) writes the tags' time there before it answers, so that when the CDN is purged next, no instance can give it an old page. The CDN keeps pages (`s-maxage=60`, `stale-while-revalidate`, `stale-if-error`). This replaces ISR's page cache and keeps what ISR is for: a page is made once, kept, and made again when told.

**The policy** (amended 2026-11-26). The first version put a nonce in each page. But a page the CDN keeps is served to many readers, so its nonce is no longer secret: anyone can read it and use it in markup injected elsewhere. Since no page needs an inline script, there is no nonce at all: one strict policy, the same on every page (`lib/csp.ts`): `script-src 'self'`; `style-src 'self'` plus the hash of the failure page's fixed style; `object-src`, `base-uri`, `frame-ancestors 'none'`; `form-action 'self'`; images, media and connections only from this origin and the media CDN; frames only from youtube-nocookie; Trusted Types required, with one policy, `navigate`, for the only HTML the islands parse (our own documents, parsed inert); violations reported to `/api/csp-report`, which logs origin and path and never the query. The reader's scheme and text size are set before first paint by `islands/early.ts`, a 190-byte classic script file, cached for a year. `lib/slim.ts` keeps a script only if it is one of these files, so no inline script can reach a reader even by mistake; tests hold every page to that.

**True statuses.** 404, 301 (a 308 of the framework is turned into 301) and 503 are decided before the first byte. A failed page is designed, needs nothing, says `no-store` and 503, so the CDN goes on showing what it has.

**Moving inside the site** fetches the next document (the same one the CDN keeps) and puts it in place; after 90 ms its skeleton is shown. A bar in the brand's red runs along the top while a page is slower than 120 ms, creeping towards 90% and filling when the page is in (`islands/progress.ts`): no full reload, and no flash on a quick one. A page kept for Back is put back at once, with no bar. Skeletons are the server's own components without data, fetched once (`/skeletons`). Anything unusual (another language, release or theme, an error) is an ordinary navigation, so nothing depends on it. Without script every page is complete.

## Alternatives
A nonce per page (unsafe once the CDN keeps the page); hashes for an inline early script (a file costs one cached request and keeps the policy free of inline code). Hydrating everything and asking for a larger budget (on a cheap phone and bought data, the reader pays for it). Pages Router with no runtime (no Server Components). Astro (a second framework beside the console's). `loading.tsx` (statuses).

## Consequences
React does not run in the reader's browser. M4's comments and sign-in are React islands, bundled the same way and fetched when opened: react-dom (about 60 KB) fits the budget because it is not in every page. `next dev` sends the framework as usual; the islands then leave players to it. A shared component that must work on the website says what it does in data attributes (`data-do`).

**Guarded.** Because all of this depends on what Next renders, Next is pinned to an exact version and Dependabot proposes patches only; `web/test/document.test.ts` and `support/tests/e2e/web/contract.spec.ts` fail if an upgrade puts the framework's runtime, its flight data or an inline script back into a page, makes the islands larger than 6 KB, or changes a status. How to upgrade: [upgrade-next.md](../runbooks/upgrade-next.md).
