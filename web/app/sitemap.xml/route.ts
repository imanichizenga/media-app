import { sitemapIndex } from "@/lib/api";
import { XML } from "@/lib/cdn";
import { absolute } from "@/lib/seo";
import { index } from "@/lib/xml";

export const dynamic = "force-dynamic";
export async function GET() {
  const { months } = await sitemapIndex();
  const latest = months[0]?.modified_at;
  return new Response(
    index([
      { loc: absolute("/sitemaps/news.xml"), modified: latest },
      { loc: absolute("/sitemaps/pages.xml"), modified: latest },
      ...months.flatMap((m) => [
        { loc: absolute(`/sitemaps/stories-${m.month}.xml`), modified: m.modified_at },
        { loc: absolute(`/sitemaps/images-${m.month}.xml`), modified: m.modified_at },
        ...(m.videos > 0
          ? [{ loc: absolute(`/sitemaps/videos-${m.month}.xml`), modified: m.modified_at }]
          : []),
      ]),
    ]),
    { headers: XML },
  );
}
