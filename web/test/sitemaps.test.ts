import { readFileSync } from "node:fs";
import { describe, expect, test } from "vitest";
import { validateXML } from "xmllint-wasm";
import { atom, rss } from "@/lib/feeds";
import { imagesMap, newsMap, storiesMap, videosMap } from "@/lib/sitemaps";
import { index } from "@/lib/xml";
import { article, entry, site, video } from "./data";

const xsd = (name: string) => readFileSync(new URL(`./xsd/${name}.xsd`, import.meta.url), "utf8");
/** The official schemas, with their extensions imported. */
async function check(xml: string, schema: "sitemap" | "siteindex" = "sitemap") {
  const spaces = {
    news: "http://www.google.com/schemas/sitemap-news/0.9",
    image: "http://www.google.com/schemas/sitemap-image/1.1",
    video: "http://www.google.com/schemas/sitemap-video/1.1",
  };
  const wrapper = `<?xml version="1.0"?><xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<xsd:import namespace="http://www.sitemaps.org/schemas/sitemap/0.9" schemaLocation="${schema}.xsd"/>
${Object.entries(spaces)
  .map(([name, ns]) => `<xsd:import namespace="${ns}" schemaLocation="${name}.xsd"/>`)
  .join("")}</xsd:schema>`;
  const result = await validateXML({
    xml: [{ fileName: "map.xml", contents: xml }],
    schema: [wrapper],
    preload: [schema, "news", "image", "video"].map((n) => ({ fileName: `${n}.xsd`, contents: xsd(n) })),
  });
  // The schema's strict wildcard knows no XHTML; hreflang links are Google's own documented extension, checked below.
  return result.errors.map((e) => e.message).filter((m) => !m.includes("{http://www.w3.org/1999/xhtml}link"));
}
const now = Date.parse("2026-11-25T08:00:00Z");

describe("sitemaps pass the official schemas", () => {
  test("news", async () => {
    const xml = newsMap(site, [entry], now);
    expect(await check(xml)).toEqual([]);
    expect(xml).toContain("<news:name>Mfano &amp; News</news:name>");
    expect(xml).toContain("Baraza &amp; &lt;bajeti&gt;");
  });
  test("news keeps 48 hours, and no more than a thousand", () => {
    const at = (ms: number) => ({ ...entry, published_at: new Date(ms).toISOString() });
    const day = 86_400_000;
    expect(newsMap(site, [at(now - 2 * day - 1), at(now + day)], now)).not.toContain("<url>");
    expect(newsMap(site, Array(1200).fill(at(now - 1000)), now).split("<url>")).toHaveLength(1001);
  });
  test("stories, with their other language", async () => {
    const xml = storiesMap([entry]);
    expect(await check(xml)).toEqual([]);
    expect(xml).toContain('hreflang="en" href="http://localhost:3000/en/politics/story"');
    expect(xml).toContain('hreflang="x-default" href="http://localhost:3000/siasa/habari"');
  });
  test("pictures", async () => expect(await check(imagesMap(site, [entry]))).toEqual([]));
  test("videos", async () => {
    const list = [
      { ...entry, type: "video", video, duration_ms: 95_000 },
      { ...entry, type: "youtube", youtube_id: "dQw4w9WgXcQ", image: null },
      { ...entry, type: "video" },
    ] as (typeof entry)[];
    const xml = videosMap(site, list);
    expect(await check(xml)).toEqual([]);
    expect(xml.split("<url>")).toHaveLength(3); // one without anywhere to play is left out
  });
  test("the index", async () =>
    expect(
      await check(index([{ loc: "https://x.example/a.xml", modified: entry.modified_at }]), "siteindex"),
    ).toEqual([]));
  test("the check can fail", async () =>
    expect(
      await check(
        newsMap(site, [entry], now)
          .replace("<news:title>", "<news:titel>")
          .replace("</news:title>", "</news:titel>"),
      ),
    ).not.toEqual([]));
});

describe("feeds", () => {
  const feed = {
    site,
    locale: "sw" as const,
    title: "T",
    path: "/siasa",
    self: "/rss/siasa",
    list: [article],
  };
  test("are well-formed and say their words safely", async () => {
    for (const xml of [rss(feed), atom(feed)]) {
      expect(xml).toContain("Baraza &lt;lapitisha&gt; bajeti");
      const { errors } = await validateXML({
        xml,
        schema: '<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"/>',
      });
      // No schema describes them; not being well-formed is another error than having no declaration.
      expect(errors.filter((e) => !/No matching global|declaration/.test(e.message))).toEqual([]);
    }
  });
});
