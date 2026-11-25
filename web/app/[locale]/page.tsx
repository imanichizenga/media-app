import type { Metadata } from "next";
import { LeadCard, LiveRail, RowCard, SectionHeading, StoryCard } from "@news/ui/news";
import { Frame, Wide } from "@/components/frame";
import { JsonLd } from "@/components/json-ld";
import { type Maybe, River, Rows, Strip } from "@/components/parts";
import { home, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { graph, organization, website } from "@/lib/seo";
import { cards, isBreaking, viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const other: Locale = locale === "sw" ? "en" : "sw";
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/"),
    others: [{ locale: other, path: at(other, "/") }],
  });
}

export default async function Page({ params }: Props) {
  const { locale } = await params;
  const [site, h] = await Promise.all([readSite(), home(locale)]);
  const view = viewOf(locale, site);
  const t = words(locale);
  const hot = h.breaking.find((c) => isBreaking(c, view.now));
  const lead: Maybe[] = cards(h.lead.filter((c) => c.id !== hot?.id));
  const latest: Maybe[] = cards(h.latest.filter((c) => c.id !== hot?.id));
  const path = at(locale, "/");
  return (
    <Frame
      locale={locale}
      path={path}
      place="home"
      view={view}
      breaking={hot && cards([hot])[0]}
      other={at(locale === "sw" ? "en" : "sw", "/")}
    >
      <JsonLd data={graph(organization(site), website(site, locale))} />
      <h1 className="sr-only">{site.identity.brand_name}</h1>
      <Wide className="lg:pt-4">
        <LiveRail cards={cards(h.live)} env={view} title={t("liveNow")} />
        <div className="grid gap-x-8 gap-y-6 lg:grid-cols-12 lg:pt-4">
          <LeadCard card={lead[0]} env={view} priority className="lg:col-span-6" />
          <div className="lg:col-span-3">
            <div className="hidden flex-col gap-6 lg:flex">
              {lead.slice(1, 3).map((card, i) => (
                <StoryCard key={card?.id ?? i} card={card} env={view} />
              ))}
            </div>
            <div className="lg:hidden">
              <Rows list={lead.slice(1, 5)} env={view} />
            </div>
          </div>
          <div className="lg:col-span-3">
            <River list={latest.slice(0, 7)} env={view} title={t("latest")} href={at(locale, "/latest")} />
          </div>
        </div>
      </Wide>
      {h.videos.length > 0 && (
        <section aria-label={t("videos")} className="mt-12 bg-surface-sunken py-8">
          <Wide>
            <SectionHeading title={t("videos")} href={at(locale, "/video")} env={view} />
            <Strip list={cards(h.videos).slice(0, 4)} env={view} />
            {h.shorts.length > 0 && (
              <div className="pt-8">
                <SectionHeading title={t("shorts")} href={at(locale, "/shorts")} env={view} />
                <Strip list={cards(h.shorts).slice(0, 6)} env={view} shorts />
              </div>
            )}
          </Wide>
        </section>
      )}
      <Wide className="flex flex-col gap-12 pt-12">
        {h.sections.map((section, i) => {
          const list = cards(section.results);
          return (
            <section key={section.category.id} aria-label={section.category.name}>
              <SectionHeading title={section.category.name} href={section.category.path} env={view} />
              {i % 2 === 0 ? (
                <div className="grid gap-x-8 gap-y-6 lg:grid-cols-12">
                  <StoryCard card={list[0]} env={view} className="lg:col-span-5" />
                  <ul className="divide-y divide-border lg:col-span-7">
                    {list.slice(1, 4).map((card) => (
                      <li key={card.id} className="py-4 first:pt-0">
                        <RowCard card={card} env={view} />
                      </li>
                    ))}
                  </ul>
                </div>
              ) : (
                <ul className="grid grid-cols-2 gap-x-4 gap-y-8 lg:grid-cols-4 lg:gap-x-8">
                  {list.slice(0, 4).map((card) => (
                    <li key={card.id} className="min-w-0">
                      <StoryCard card={card} env={view} />
                    </li>
                  ))}
                </ul>
              )}
            </section>
          );
        })}
      </Wide>
    </Frame>
  );
}
