import "server-only";
import { type Card, category, latest, orNull, site as readSite, type Site } from "./api";
import { XML } from "./cdn";
import { words } from "./i18n";
import { at, type Locale } from "./locale";
import { absolute, crops } from "./seo";
import { el, x } from "./xml";

export type FeedOf = { site: Site; locale: Locale; title: string; path: string; self: string; list: Card[] };
const newest = (list: Card[]) =>
  list
    .map((c) => c.modified_at)
    .sort()
    .at(-1) ?? "";

export const rss = ({ site, locale, title, path, self, list }: FeedOf) =>
  `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/" xmlns:dc="http://purl.org/dc/elements/1.1/"><channel>${el("title", title)}${el("link", absolute(path))}${el("description", (locale === "en" ? site.identity.tagline_en : site.identity.tagline_sw) || title)}${el("language", locale)}${newest(list) ? el("lastBuildDate", new Date(newest(list)).toUTCString()) : ""}<atom:link href="${x(absolute(self))}" rel="self" type="application/rss+xml"/>
${list
  .map((c) => {
    const picture = c.is_sensitive ? undefined : crops(site, c.image)[0];
    return `<item>${el("title", c.headline)}${el("link", absolute(c.path))}<guid isPermaLink="false">${x(c.id)}-${x(c.locale)}</guid>${el("pubDate", new Date(c.published_at).toUTCString())}${el("description", c.standfirst)}${el("category", c.category.name)}${c.authors.map((a) => el("dc:creator", a.name)).join("")}${picture ? `<media:content url="${x(picture)}" medium="image" type="image/jpeg"/>` : ""}</item>`;
  })
  .join("\n")}
</channel></rss>
`;

export const atom = ({ site, locale, title, path, self, list }: FeedOf) =>
  `<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="${locale}">${el("title", title)}${el("id", absolute(self))}<link rel="alternate" type="text/html" href="${x(absolute(path))}"/><link rel="self" type="application/atom+xml" href="${x(absolute(self))}"/>${el("updated", newest(list) || "1970-01-01T00:00:00Z")}<author>${el("name", site.identity.brand_name)}</author>
${list
  .map(
    (c) =>
      `<entry>${el("title", c.headline)}<link href="${x(absolute(c.path))}"/>${el("id", `urn:uuid:${c.id}:${c.locale}`)}${el("published", c.published_at)}${el("updated", c.modified_at)}${el("summary", c.standfirst || c.headline)}${c.authors.map((a) => `<author>${el("name", a.name)}${el("uri", absolute(a.path))}</author>`).join("")}<category term="${x(c.category.slug)}" label="${x(c.category.name)}"/></entry>`,
  )
  .join("\n")}
</feed>
`;

/** /rss, /rss/en, /rss/<category>, /rss/en/<category>; the same under /feed in Atom. */
export async function feedResponse(base: "rss" | "feed", parts: string[] = []) {
  const locale: Locale = parts[0] === "en" ? "en" : "sw";
  const [slug, ...more] = locale === "en" ? parts.slice(1) : parts;
  if (more.length > 0) return new Response("Not found", { status: 404 });
  const found = slug
    ? await orNull(category(locale, slug, { limit: 30 }))
    : { ...(await latest(locale, { limit: 30 })), category: null };
  if (!found) return new Response("Not found", { status: 404 });
  const site = await readSite();
  const name = found.category?.name ?? words(locale)("latest");
  const feed = {
    site,
    locale,
    title: `${site.identity.brand_name}: ${name}`,
    path: found.category?.path ?? at(locale, "/latest"),
    self: `/${[base, ...parts].join("/")}`,
    list: found.results,
  };
  return new Response(base === "rss" ? rss(feed) : atom(feed), {
    headers: { ...XML, "content-type": `application/${base === "rss" ? "rss" : "atom"}+xml; charset=utf-8` },
  });
}
