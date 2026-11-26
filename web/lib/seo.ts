import "server-only";
import type { Article, Card, Site } from "./api";
import { env } from "./env";
import { at, type Locale } from "./locale";
import { blocksText } from "./text";

export const absolute = (path: string) => `${env.site}${path === "/" ? "" : path}`;
export const mediaUrl = (site: Site, key: string) =>
  /^https?:/.test(key)
    ? key
    : key.startsWith("/") || !site.media_base_url
      ? absolute(`/${key.replace(/^\//, "")}`)
      : `${site.media_base_url}/${key}`;
/** Google asks for three shapes, each at least 1200 wide; the API cut them when the picture was uploaded. */
export function crops(site: Site, image: Card["image"]): string[] {
  if (!image?.crops) return [];
  return ["16x9", "4x3", "1x1"].map((r) => mediaUrl(site, `${image.crops}crop-${r}.jpg`));
}
const thumbnail = (site: Site, c: Pick<Card, "image" | "video" | "youtube_id">): string[] => [
  ...crops(site, c.image),
  ...(c.video?.poster ? [mediaUrl(site, c.video.poster)] : []),
  ...(c.youtube_id ? [`https://i.ytimg.com/vi/${c.youtube_id}/hqdefault.jpg`] : []),
];
export const duration = (ms: number | null) =>
  ms ? `PT${Math.floor(ms / 60_000)}M${Math.round(ms / 1000) % 60}S` : undefined;

export function organization(site: Site, locale: Locale = "sw") {
  const logo = site.identity.symbol ?? site.identity.wordmark_light;
  // The brand's own line in the reader's language (Google recommends a description); absent if not written.
  const description = (locale === "en" ? site.identity.tagline_en : site.identity.tagline_sw)?.trim();
  return {
    "@type": "NewsMediaOrganization",
    "@id": `${absolute("/")}/#organization`,
    name: site.identity.brand_name,
    url: absolute("/"),
    ...(description ? { description } : {}),
    ...(logo
      ? {
          logo: {
            "@type": "ImageObject",
            url: absolute(logo.png["3x"] ?? Object.values(logo.png)[0] ?? ""),
            width: logo.width,
            height: logo.height,
          },
        }
      : {}),
    ...(site.seo.same_as.length ? { sameAs: site.seo.same_as } : {}),
    publishingPrinciples: absolute("/editorial-policy"),
    correctionsPolicy: absolute("/corrections"),
  };
}
export const website = (site: Site, locale: Locale) => ({
  "@type": "WebSite",
  "@id": `${absolute("/")}/#website`,
  name: site.identity.brand_name,
  url: absolute(at(locale, "/")),
  inLanguage: locale,
  publisher: { "@id": `${absolute("/")}/#organization` },
});
export const breadcrumbs = (items: { name: string; path: string }[]) => ({
  "@type": "BreadcrumbList",
  itemListElement: items.map((item, i) => ({
    "@type": "ListItem",
    position: i + 1,
    name: item.name,
    item: absolute(item.path),
  })),
});
export function videoObject(site: Site, c: Card) {
  const embed = c.youtube_id ? `https://www.youtube-nocookie.com/embed/${c.youtube_id}` : undefined;
  return {
    "@type": "VideoObject",
    name: c.headline,
    description: c.standfirst || c.headline,
    thumbnailUrl: thumbnail(site, c),
    uploadDate: c.published_at,
    ...(duration(c.duration_ms) ? { duration: duration(c.duration_ms) } : {}),
    ...(c.video ? { contentUrl: mediaUrl(site, c.video.hls) } : {}),
    ...(embed ? { embedUrl: embed } : {}),
  };
}
export function newsArticle(site: Site, a: Article) {
  const live = a.type === "live_blog";
  const url = absolute(a.path);
  const common = {
    headline: a.headline.slice(0, 110),
    description: a.seo.description,
    image: crops(site, a.image),
    datePublished: a.published_at,
    dateModified: a.modified_at,
    author: a.authors.map((p) => ({ "@type": "Person", name: p.name, url: absolute(p.path) })),
    publisher: organization(site, a.locale === "en" ? "en" : "sw"),
    mainEntityOfPage: { "@type": "WebPage", "@id": url },
    url,
    inLanguage: a.locale,
    articleSection: a.category.name,
    ...(a.tags.length ? { keywords: a.tags.map((x) => x.name) } : {}),
    isAccessibleForFree: true,
    ...(a.correction_note ? { correction: a.correction_note } : {}),
  };
  if (!live) return { "@type": "NewsArticle", ...common, wordCount: blocksText(a.body).split(/\s+/).length };
  const updates = (a.body.blocks as { type: string; id: string; time: string; title?: string }[]).filter(
    (b) => b.type === "live_update",
  );
  return {
    "@type": "LiveBlogPosting",
    ...common,
    coverageStartTime: a.first_published_at ?? a.published_at,
    ...(a.live_ended_at ? { coverageEndTime: a.live_ended_at } : {}),
    liveBlogUpdate: updates.map((b) => ({
      "@type": "BlogPosting",
      headline: (b.title || a.headline).slice(0, 110),
      datePublished: b.time,
      url: `${url}#${b.id}`,
      articleBody: blocksText({ blocks: (b as unknown as { blocks: unknown[] }).blocks }),
    })),
  };
}
export const graph = (...items: object[]) => ({ "@context": "https://schema.org", "@graph": items });
/** Inside a script element: nothing in it can close that element. */
export const json = (value: object) =>
  JSON.stringify(value)
    .replace(/</g, "\\u003c")
    .replace(/\u2028/g, "\\u2028")
    .replace(/\u2029/g, "\\u2029");
