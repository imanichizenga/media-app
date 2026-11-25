import type { NewsEnv } from "@news/ui/news";
import type { Metadata } from "next";
import { ExploreView, faceOf } from "@/components/explore";
import { home, navigation, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const other: Locale = locale === "sw" ? "en" : "sw";
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/search"),
    title: words(locale)("navExplore"),
    description: words(locale)("searchSoon"),
    others: [{ locale: other, path: at(other, "/search") }],
    index: false,
  });
}

async function Explore({ locale, view }: { locale: Locale; view: NewsEnv }) {
  const [nav, h] = await Promise.all([navigation(locale), home(locale)]);
  const stories = [...h.latest, ...h.videos, ...h.lead];
  const people = new Map([...h.lead, ...h.latest].flatMap((c) => c.authors.map((a) => [a.path, a] as const)));
  return (
    <ExploreView
      locale={locale}
      view={view}
      nav={nav}
      faces={nav.map((n) => faceOf(n, stories, h.sections))}
      people={[...people.values()].slice(0, 12)}
    />
  );
}
export default async function Page({ params }: Props) {
  const { locale } = await params;
  const view = viewOf(locale, await readSite());
  return <Explore locale={locale} view={view} />;
}
