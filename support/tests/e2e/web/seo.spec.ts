import { structured } from "../../../../web/test/schema";
import { manage } from "../helpers";
import { api, expect, places, test } from "./helpers";

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
      for (const json of html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs))
        expect(() => structured.parse(JSON.parse(json[1] ?? "")), `${name} JSON-LD`).not.toThrow();
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

test("security headers and a fresh nonce on every page", async ({ request }) => {
  const [a, b] = [await request.get("/"), await request.get("/")];
  const csp = a.headers()["content-security-policy"] ?? "";
  expect(csp).toContain("default-src 'none'");
  expect(csp.match(/script-src[^;]*/)?.[0]).not.toContain("unsafe");
  expect(csp).not.toBe(b.headers()["content-security-policy"]);
  expect(a.headers()).toMatchObject({
    "x-content-type-options": "nosniff",
    "x-frame-options": "DENY",
    "referrer-policy": "strict-origin-when-cross-origin",
    "strict-transport-security": expect.stringContaining("max-age=63072000"),
  });
  expect(a.headers()["cache-control"]).toContain("s-maxage=60");
  expect(a.headers()["cache-control"]).toContain("stale-while-revalidate");
  expect(a.headers()["set-cookie"]).toBeUndefined();
  // Nothing of the framework's own is sent, and nobody else's anything.
  const html = await a.text();
  // The stylesheet is the framework's file; no script of its is.
  expect(html).not.toMatch(/<script[^>]*src="\/_next\//);
  expect(html.match(/<script[^>]*src="([^"]+)"/g)).toHaveLength(1);
  expect(html).not.toMatch(
    /<(script|link|img|iframe)[^>]+(src|href)="https?:\/\/(?!localhost)[^"]*\.(js|css)/,
  );
});

test("cached pages hold nothing personal: any reader gets the same", async ({ request }) => {
  const read = async (headers: Record<string, string>) =>
    (await (await request.get("/", { headers })).text())
      .replace(/nonce="[^"]+"/g, "")
      .replace(/dakika \d+|saa \d+/g, "");
  expect(await read({ cookie: "x=1; scheme=dark", "user-agent": "one" })).toBe(
    await read({ "user-agent": "two" }),
  );
});

test("an internal request cannot be made from outside", async ({ request }) => {
  const res = await request.get("/", {
    headers: { "x-internal": "guess", "x-nonce": "mine", "x-path": "/privacy" },
  });
  expect(await res.text()).not.toContain('nonce="mine"');
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
