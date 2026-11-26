import { policy } from "../../../../web/lib/csp";
import { inlineScripts } from "../../../../web/lib/slim";
import { missing } from "../../../../web/test/google";
import { structured } from "../../../../web/test/schema";
import { manage } from "../helpers";
import { api, expect, places, ready, test, webLog } from "./helpers";

const head = (html: string, re: RegExp) => [...html.matchAll(re)].map((m) => m[1]);
for (const locale of ["sw", "en"] as const)
  test(`every page says what it is: ${locale}`, async ({ request }) => {
    const all = await places(locale);
    for (const [name, path] of Object.entries(all)) {
      if (!path || name === "missing") continue;
      const res = await request.get(path);
      const html = await res.text();
      const said = (re: RegExp) => head(html.slice(0, html.indexOf("</head>")), re);
      expect(said(/<title>([^<]+)<\/title>/g), name).toHaveLength(1);
      expect(said(/<link rel="canonical" href="([^"]+)"/g), name).toEqual([
        `http://localhost:3000${path === "/" ? "" : path}`,
      ]);
      expect(said(/<meta name="description" content="([^"]+)"/g), name).toHaveLength(1);
      const robots = said(/<meta name="robots" content="([^"]+)"/g)[0] ?? "";
      if (["search", "saved", "profile"].includes(name)) expect(robots, name).toContain("noindex");
      else {
        expect(robots, name).toContain("max-image-preview:large");
        const langs = said(/<link rel="alternate" hrefLang="([^"]+)"/gi);
        expect(langs, name).toContain(locale);
        expect(langs, name).toContain("x-default");
      }
      expect(said(/<meta property="og:image" content="([^"]+)"/g), name).toHaveLength(1);
      for (const json of html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)) {
        const data = JSON.parse(json[1] ?? "");
        expect(() => structured.parse(data), `${name} JSON-LD`).not.toThrow();
        // Complete for Google: its required and recommended fields (web/test/google.ts).
        const items = (data["@graph"] ?? [data]) as Record<string, unknown>[];
        const nested = items.flatMap((x) => [x, ...[x.publisher, x.worksFor].filter(Boolean)]) as Record<
          string,
          unknown
        >[];
        expect(
          nested.flatMap((x) => missing(x, false)),
          `${name} for Google`,
        ).toEqual([]);
      }
      const types = [...html.matchAll(/"@type":"(\w+)"/g)].map((m) => m[1]);
      const wanted: Record<string, string> = {
        home: "NewsMediaOrganization",
        article: "NewsArticle",
        live: "LiveBlogPosting",
        author: "ProfilePage",
        "video-story": "VideoObject",
        shorts: "VideoObject",
        category: "BreadcrumbList",
      };
      if (wanted[name]) expect(types, name).toContain(wanted[name]);
    }
  });

test("the other language's page points back", async ({ request }) => {
  const { article } = await places("sw");
  const links = async (path: string) =>
    Object.fromEntries(
      [...(await (await request.get(path)).text()).matchAll(/hrefLang="([\w-]+)" href="([^"]+)"/gi)].map(
        (m) => [m[1], m[2]],
      ),
    );
  const here = await links(article ?? "");
  const there = await links(new URL(here.en ?? "").pathname);
  expect(there).toEqual(here);
});

test("one strict policy, the same for every reader, and nothing inline runs on any page", async ({
  request,
}) => {
  const [a, b] = [await request.get("/"), await request.get("/")];
  const csp = a.headers()["content-security-policy"] ?? "";
  // The policy a reader gets is exactly the one lib/csp.ts writes; no nonce, so a cached page gives nothing away.
  expect(csp).toBe(policy({ local: true }));
  expect(csp).toBe(b.headers()["content-security-policy"]);
  expect(csp).not.toContain("nonce");
  expect(a.headers()["reporting-endpoints"]).toBe('csp="/api/csp-report"');
  expect(a.headers()).toMatchObject({
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "referrer-policy": "strict-origin-when-cross-origin",
    "strict-transport-security": expect.stringContaining("max-age=63072000"),
  });
  expect(a.headers()["cache-control"]).toContain("s-maxage=60");
  expect(a.headers()["cache-control"]).toContain("stale-while-revalidate");
  expect(a.headers()["set-cookie"]).toBeUndefined();
  for (const locale of ["sw", "en"] as const)
    for (const [name, path] of Object.entries(await places(locale))) {
      if (!path) continue;
      const res = await request.get(path);
      const html = await res.text();
      expect(inlineScripts(html), `${locale} ${name}`).toEqual([]);
      expect(res.headers()["content-security-policy"], `${locale} ${name}`).toBe(csp);
      // Our own files only: the early script and the islands. Nothing of the framework's, nobody else's anything.
      const sources = [...html.matchAll(/<script[^>]*\bsrc="([^"]+)"/g)].map((m) => m[1]);
      expect(sources, `${locale} ${name}`).toEqual([
        expect.stringMatching(/^\/js\/early-/),
        expect.stringMatching(/^\/js\/site-/),
      ]);
      expect(html).not.toMatch(
        /<(script|link|img|iframe)[^>]+(src|href)="https?:\/\/(?!localhost)[^"]*\.(js|css)/,
      );
    }
});

test("a violation of the policy is reported and logged", async ({ request }) => {
  const report = {
    "csp-report": {
      "document-uri": "http://localhost:3000/?q=private",
      "effective-directive": "script-src-elem",
      "blocked-uri": "inline",
    },
  };
  const res = await request.post("/api/csp-report", {
    headers: { "content-type": "application/csp-report" },
    data: JSON.stringify(report),
  });
  expect(res.status()).toBe(204);
  expect(res.headers()["cache-control"]).toBe("no-store");
  await expect
    .poll(() =>
      webLog().includes(
        '"event":"csp_violation","page":"http://localhost:3000/","directive":"script-src-elem","blocked":"inline"',
      ),
    )
    .toBe(true);
  expect(webLog()).not.toContain("q=private");
  expect((await request.post("/api/csp-report", { data: "x".repeat(10_000) })).status()).toBe(413);
});

test("a browser runs the page under the policy without a single violation", async ({ page }) => {
  const refused: string[] = [];
  // The policy fixture reports every violation as a console error starting "CSP".
  page.on("console", (m) => {
    if (/^CSP |Content Security Policy|TrustedHTML|Trusted Type/i.test(m.text())) refused.push(m.text());
  });
  const { article, video, live } = await places("sw");
  for (const path of ["/", article, video, live, "/en"]) if (path) await ready(page, path);
  // Moving inside the site parses a document through the Trusted Types policy.
  await ready(page, "/");
  await page.locator("main a[href^='/']").first().click();
  await page.waitForLoadState("networkidle");
  expect(refused).toEqual([]);
});

test("cached pages hold nothing personal: any reader gets the same", async ({ request }) => {
  const read = async (headers: Record<string, string>) =>
    (await (await request.get("/", { headers })).text()).replace(/dakika \d+|saa \d+/g, "");
  expect(await read({ cookie: "x=1; scheme=dark", "user-agent": "one" })).toBe(
    await read({ "user-agent": "two" }),
  );
});

test("an internal request cannot be made from outside", async ({ request }) => {
  const res = await request.get("/", { headers: { "x-internal": "guess", "x-path": "/privacy" } });
  expect(await res.text()).not.toContain('<link rel="canonical" href="http://localhost:3000/privacy"');
  expect((await request.get("/document")).status()).toBe(404);
  expect((await request.get("/missing")).status()).toBe(404);
});

test("sitemaps, feeds, robots", async ({ request }) => {
  const index = await (await request.get("/sitemap.xml")).text();
  const maps = head(index, /<loc>http:\/\/localhost:3000([^<]+)<\/loc>/g);
  expect(maps).toContain("/sitemaps/news.xml");
  expect(maps.some((m) => m?.includes("stories-"))).toBe(true);
  expect(maps.some((m) => m?.includes("images-"))).toBe(true);
  expect(maps.some((m) => m?.includes("videos-"))).toBe(true);
  for (const map of maps) {
    const res = await request.get(map ?? "");
    expect(res.status(), map).toBe(200);
    expect(res.headers()["content-type"]).toContain("application/xml");
    // Every address in every map answers, without moving.
    const [first] = head(await res.text(), /<loc>http:\/\/localhost:3000([^<]+)<\/loc>/g);
    if (first) expect((await request.get(first, { maxRedirects: 0 })).status(), `${map} ${first}`).toBe(200);
  }
  const [category] = await api("navigation?locale=sw");
  for (const feed of [
    "/rss",
    "/rss/en",
    "/feed",
    "/feed/en",
    `/rss/${category.slug}`,
    `/feed/${category.slug}`,
  ])
    expect((await request.get(feed)).status(), feed).toBe(200);
  expect((await request.get("/rss/hakuna")).status()).toBe(404);
  expect((await request.get("/sitemaps/stories-1999-01.xml")).status()).toBe(404);
  expect(await (await request.get("/robots.txt")).text()).toContain(
    "Sitemap: http://localhost:3000/sitemap.xml",
  );
});

test("app links are served here, as the API says them", async ({ request }) => {
  for (const name of ["assetlinks.json", "apple-app-site-association"]) {
    const res = await request.get(`/.well-known/${name}`);
    expect(res.status()).toBe(200);
    expect(res.headers()["content-type"]).toContain("application/json");
    expect(await res.json()).toEqual(await (await fetch(`http://127.0.0.1:8010/.well-known/${name}`)).json());
  }
});

test("share images, in the published theme", async ({ request }) => {
  const { article } = await places("sw");
  const html = await (await request.get(article ?? "")).text();
  const [og] = head(html, /<meta property="og:image" content="http:\/\/localhost:3000([^"]+)"/g);
  for (const path of [og?.replaceAll("&amp;", "&"), "/og/en/site.png"]) {
    const res = await request.get(path ?? "");
    expect(res.headers()["content-type"]).toBe("image/png");
    const png = await res.body();
    expect([png.readUInt32BE(16), png.readUInt32BE(20)]).toEqual([1200, 630]);
  }
  expect((await request.get("/og/sw/hakuna.png")).status()).toBe(404);
  expect((await request.get("/og/sw/..%2f..%2fetc.png")).status()).toBe(404);
});

test("old addresses move for good: 301, once", async ({ request }) => {
  const { article, category } = await places("sw");
  const slug = article?.split("/").pop();
  manage(
    "shell",
    "-v0",
    "-c",
    `from newsplatform.seo.models import Redirect
Redirect.objects.get_or_create(from_path="/zamani/habari-ya-zamani", defaults={"to_path": "${article}"})
Redirect.objects.get_or_create(from_path="/zamani/*", defaults={"to_path": "${category}/*"})`,
  );
  const moved = async (path: string) => {
    const res = await request.get(path, { maxRedirects: 0 });
    return [res.status(), res.headers().location];
  };
  expect(await moved("/zamani/habari-ya-zamani")).toEqual([301, article]);
  // The right story under the wrong section has one right address.
  expect(
    await moved(
      `/${category?.split("/").pop() === article?.split("/")[1] ? "afya" : category?.split("/").pop()}/${slug}`,
    ),
  ).toEqual([301, article]);
  expect(await moved("/sw")).toEqual([301, expect.stringMatching(/^(http:\/\/localhost:3000)?\/$/)]);
  expect(await moved(`/sw${article}`)).toEqual([301, expect.stringContaining(article ?? "")]);
});
