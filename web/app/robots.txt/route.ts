import { env } from "@/lib/env";
import { absolute } from "@/lib/seo";

export const dynamic = "force-dynamic";
export function GET() {
  const lines = env.closed
    ? ["User-agent: *", "Disallow: /"]
    : [
        "User-agent: *",
        "Allow: /",
        "Disallow: /api/",
        // Device-local pages: nothing in them for anyone else.
        "Disallow: /saved",
        "Disallow: /en/saved",
        "Disallow: /profile",
        "Disallow: /en/profile",
        "",
        `Sitemap: ${absolute("/sitemap.xml")}`,
        `Sitemap: ${absolute("/sitemaps/news.xml")}`,
      ];
  return new Response(`${lines.join("\n")}\n`, {
    headers: {
      "content-type": "text/plain; charset=utf-8",
      "cache-control": "public, max-age=300, s-maxage=3600",
    },
  });
}
