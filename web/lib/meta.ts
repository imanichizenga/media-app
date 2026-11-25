import "server-only";
import type { Metadata } from "next";
import type { Site } from "./api";
import { env } from "./env";
import { bare, type Locale } from "./locale";
import { absolute } from "./seo";

/** Title, description, canonical, the other language, and what is shown when the page is shared. */
export function metaOf({
  site,
  locale,
  path,
  title,
  description,
  others = [],
  index = true,
  og,
  type = "website",
  article,
}: {
  site: Site;
  locale: Locale;
  path: string;
  title?: string;
  description?: string;
  /** The same page in other languages. */
  others?: { locale: string; path: string }[];
  index?: boolean;
  og?: string;
  type?: "website" | "article";
  article?: { published: string; modified: string; section: string; authors: string[] };
}): Metadata {
  const name = site.identity.brand_name;
  const tagline = locale === "en" ? site.identity.tagline_en : site.identity.tagline_sw;
  const full = title ? `${title} | ${name}` : tagline ? `${name}: ${tagline}` : name;
  const text = description || tagline || name;
  const languages: Record<string, string> = { [locale]: absolute(path) };
  for (const o of others) languages[o.locale] = absolute(o.path);
  // Readers of neither language are shown the default one, when it exists.
  languages["x-default"] = languages.sw ?? absolute(path);
  const image = absolute(og ?? `/og/${locale}/site.png?v=${site.theme.hash}`);
  return {
    metadataBase: new URL(env.site),
    title: full,
    description: text.slice(0, 300),
    alternates: {
      canonical: absolute(path),
      languages,
      types: { "application/rss+xml": absolute(locale === "en" ? "/rss/en" : "/rss") },
    },
    robots:
      index && !env.closed
        ? { index: true, follow: true, "max-image-preview": "large", "max-snippet": -1, "max-video-preview": -1 }
        : { index: false, follow: true },
    openGraph: {
      title: title ?? name,
      description: text.slice(0, 300),
      url: absolute(path),
      siteName: name,
      locale: locale === "en" ? "en_GB" : "sw_TZ",
      images: [{ url: image, width: 1200, height: 630, alt: title ?? name }],
      ...(type === "article" && article
        ? {
            type: "article" as const,
            publishedTime: article.published,
            modifiedTime: article.modified,
            section: article.section,
            authors: article.authors,
          }
        : { type: "website" as const }),
    },
    twitter: { card: "summary_large_image", title: title ?? name, description: text.slice(0, 200), images: [image] },
    verification: {
      ...(site.seo.google_verification ? { google: site.seo.google_verification } : {}),
      ...(site.seo.bing_verification ? { other: { "msvalidate.01": site.seo.bing_verification } } : {}),
    },
    ...(bare(path) === "/" ? { applicationName: name } : {}),
  };
}
