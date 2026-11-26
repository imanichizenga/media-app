# Upgrading Next.js

The website does not send Next's client runtime: `web/app/document` renders each page with the App Router and
`web/lib/slim.ts` takes out the framework's scripts and its second copy of the data ([ADR-0046](../adr/0046-website-rendering.md)).
That depends on what Next renders, which can change in any minor release. So Next is pinned to an exact version in
`web/package.json` and `admin/package.json`, and Dependabot proposes patches only (`.github/dependabot.yml`).

## When

A patch: when Dependabot proposes it, if CI is green (all of it: the guards below are in `e2e-web`).
A minor or major: deliberately, on its own branch, never grouped with anything else; read its release notes first.

## Steps

1. Branch `deps/next-<version>`. Set the same exact version of `next` (and `eslint-config-next` or `@next/*` if
   present) in `web/package.json` and `admin/package.json`; `pnpm install`.
2. Build both, as CI does:
   ```sh
   API_PROXY_TARGET=http://127.0.0.1:8001 REALTIME_PROXY_TARGET=http://127.0.0.1:8002 pnpm --filter @news/admin... build
   WEB_LOCAL=1 API_PROXY_TARGET=http://127.0.0.1:8010 pnpm --filter @news/web... build
   ```
3. Run the guards of the document layer:
   - `pnpm --filter @news/web test` — `test/document.test.ts` (503 with no-store, 301 for a permanent move, the
     framework's runtime and flight data taken out) and `test/safety.test.ts` (no inline script survives).
   - `pnpm --filter @news/e2e web` — `contract.spec.ts` (no `/_next/` script, no `__next_f`/`__NEXT_DATA__`/RSC
     payload on any page, islands under 6 KB, true 404 and 301), `seo.spec.ts` (one strict policy, nothing inline,
     no violation in a browser), `site.spec.ts` ("every page can be read without script"), `states.spec.ts`
     (skeletons, CLS, the fallback of inside navigation), `perf.spec.ts` (Lighthouse budgets).
4. If a guard fails, find what Next now renders differently (compare a page's raw HTML before and after:
   `curl -s -H "x-internal: …" localhost:3000/<path>` is not reachable from outside; use the e2e server and the
   failing test's output). Adapt `lib/slim.ts` or `app/document/route.ts`, never the guard, unless the guard itself
   was wrong; then say why in the pull request.
5. Check what is not tested: `next dev` still starts (`pnpm --filter @news/web dev`), the standalone output still
   has `server.js` (the Dockerfile copies it), and the `images` job's Trivy scan is clean.
6. One pull request, titled `deps: Next.js <old> → <new>`, with the Lighthouse table from the `e2e-web` summary.

## Rolling back

Revert the pull request: the version is exact, so the lockfile goes back with it.
