import { navigation, orNull, pages, site as readSite, sitemapMonth, sitemapNews } from "@/lib/api";
import { XML } from "@/lib/cdn";
import { at, LOCALES } from "@/lib/locale";
import { absolute } from "@/lib/seo";
import { imagesMap, newsMap, storiesMap, videosMap } from "@/lib/sitemaps";
import { el, urlset } from "@/lib/xml";

export const dynamic = "force-dynamic";
const VIDEO = ["video", "short", "youtube"];
const xml = (body: string) => new Response(body, { headers: XML });
const missing = () => new Response("Not found", { status: 404 });

export async function GET(_: Request, { params }: { params: Promise<{ name: string }> }) {
  const { name } = await params;
  if (name === "news.xml") {
    const [site, { results }] = await Promise.all([readSite(), sitemapNews()]);
    return xml(newsMap(site, results, Date.now()));
  }
  if (name === "pages.xml") {
    const urls: string[] = [];
    for (const locale of LOCALES) {
      const [nav, still] = await Promise.all([navigation(locale), pages(locale)]);
      urls.push(
        ...["/", "/latest", "/video", "/shorts"].map(
          (p) => `<url>${el("loc", absolute(at(locale, p)))}</url>`,
        ),
        ...nav.flatMap((n) => [n, ...n.children]).map((n) => `<url>${el("loc", absolute(n.path))}</url>`),
        ...still.results.map(
          (p) => `<url>${el("loc", absolute(p.path))}${el("lastmod", p.modified_at)}</url>`,
        ),
      );
    }
    return xml(urlset([], urls));
  }
  const [, kind, month] = /^(stories|images|videos)-(20\d\d-\d\d)\.xml$/.exec(name) ?? [];
  if (!kind || !month) return missing();
  const [site, found] = await Promise.all([readSite(), orNull(sitemapMonth(month))]);
  if (!found) return missing();
  if (kind === "stories") return xml(storiesMap(found.results));
  if (kind === "images") return xml(imagesMap(site, found.results));
  return xml(
    videosMap(
      site,
      found.results.filter((e) => VIDEO.includes(e.type)),
    ),
  );
}
