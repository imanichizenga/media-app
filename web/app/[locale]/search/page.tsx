import type { Metadata } from "next";
import { ExploreView, faceOf } from "@/components/explore";
import { Frame, Wide } from "@/components/frame";
import { Filters, Results, SearchTop } from "@/components/search";
import { home, navigation, site as readSite, search } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { addressOf, askedOf, type Wanted, wantedOf } from "@/lib/search";
import { viewOf } from "@/lib/view";

type Props = {
  params: Promise<{ locale: Locale }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

async function load({ params, searchParams }: Props) {
  const [{ locale }, raw] = await Promise.all([params, searchParams]);
  return { locale, wanted: wantedOf(raw), base: at(locale, "/search") };
}

export async function generateMetadata(props: Props): Promise<Metadata> {
  const { locale, wanted, base } = await load(props);
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  return metaOf({
    site: await readSite(),
    locale,
    path: addressOf(base, wanted),
    title: wanted.q ? t("searchResultsFor", { v: wanted.q }) : t("navExplore"),
    description: t("searchSoon"),
    others: [{ locale: other, path: addressOf(at(other, "/search"), { q: wanted.q }) }],
    // Results are for readers: a search engine finds the stories in the sitemap.
    index: false,
  });
}

async function Explore({ locale, wanted, base }: { locale: Locale; wanted: Wanted; base: string }) {
  const site = await readSite();
  const view = viewOf(locale, site);
  const t = words(locale);
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
      top={<SearchTop base={base} wanted={wanted} t={t} />}
    />
  );
}

async function Found({ locale, wanted, base }: { locale: Locale; wanted: Wanted; base: string }) {
  const site = await readSite();
  const view = viewOf(locale, site);
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  const found = await search(locale, askedOf(wanted));
  return (
    <Frame
      locale={locale}
      path={base}
      place="explore"
      view={view}
      title={t("navExplore")}
      other={addressOf(at(other, "/search"), { q: wanted.q })}
    >
      <Wide>
        <SearchTop base={base} wanted={wanted} t={t} />
        {/* What typing replaces (islands/search.ts): the filters and the results. */}
        <div data-search-body="">
          <Filters base={base} wanted={wanted} t={t} />
          <Results base={base} wanted={wanted} found={found} env={view} t={t} />
        </div>
      </Wide>
    </Frame>
  );
}

export default async function Page(props: Props) {
  const asked = await load(props);
  return asked.wanted.q ? <Found {...asked} /> : <Explore {...asked} />;
}
