import { readdirSync, readFileSync } from "node:fs";
import { gzipSync } from "node:zlib";
import { expect, places, test } from "./helpers";

// The custom document layer (ADR-0046) depends on what Next.js renders. These fail loudly if an upgrade changes it:
// support/docs/runbooks/upgrade-next.md says what to do then. The unit half is web/test/document.test.ts.
const JS = new URL("../../../../web/public/js/", import.meta.url).pathname;

test("no page carries the framework's runtime or a second copy of its data", async ({ request }) => {
  for (const locale of ["sw", "en"] as const)
    for (const [name, path] of Object.entries(await places(locale))) {
      if (!path) continue;
      const html = await (await request.get(path)).text();
      const where = `${locale} ${name}`;
      expect(html, where).not.toMatch(/<script[^>]+src="\/_next\//);
      expect(html, where).not.toMatch(/<link[^>]+as="script"/);
      expect(html, where).not.toMatch(/__next_f|__NEXT_DATA__|self\.__next|"\$Sreact|\$L[0-9a-f]+"/);
      expect(html, where).toContain("<main");
    }
});

test("the islands are under 6 KB gzipped; the player is fetched only when asked", () => {
  const files = readdirSync(JS);
  const site = files.find((f) => /^site-.*\.js$/.test(f));
  expect(site).toBeTruthy();
  const size = gzipSync(readFileSync(JS + site), { level: 9 }).length;
  expect(size, `${site}: ${size} bytes gzipped`).toBeLessThan(6 * 1024);
  const early = files.find((f) => /^early-.*\.js$/.test(f)) ?? "";
  expect(gzipSync(readFileSync(JS + early)).length).toBeLessThan(512);
});

test("true statuses: 404 in the reader's language, 301 for a moved address", async ({ request }) => {
  const missing = await request.get("/hakuna-ukurasa/huu");
  expect(missing.status()).toBe(404);
  expect(await missing.text()).toContain('lang="sw"');
  const english = await request.get("/en/no-such/page");
  expect(english.status()).toBe(404);
  expect(await english.text()).toContain('lang="en"');
  const moved = await request.get("/sw/siasa", { maxRedirects: 0 });
  expect(moved.status()).toBe(301);
  expect(moved.headers().location).toMatch(/\/siasa$/);
});
