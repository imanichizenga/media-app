import { LeadCard, LiveRail, RowCard, SectionHeading, StoryCard } from "@news/ui/news";
import { type Home, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { graph, organization, website } from "@/lib/seo";
import { cards, isBreaking, viewOf } from "@/lib/view";
import { Frame, Wide } from "./frame";
import { JsonLd } from "./json-ld";
import { type Maybe, none, River, Rows, Strip } from "./parts";

/** Without data it is its own skeleton: what cannot be known, breaking and live, is absent (V2). */
export async function HomeView({ locale, h }: { locale: Locale; h?: Home }) {
  const site = await readSite();
  const view = viewOf(locale, site);
  const t = words(locale);
  const hot = h?.breaking.find((c) => isBreaking(c, view.now));
  const lead: Maybe[] = h ? cards(h.lead.filter((c) => c.id !== hot?.id)) : none(5);
  const latest: Maybe[] = h ? cards(h.latest.filter((c) => c.id !== hot?.id)) : none(7);
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
        {h && <LiveRail cards={cards(h.live)} env={view} title={t("liveNow")} />}
        <div className="grid grid-cols-1 gap-x-8 gap-y-6 lg:grid-cols-12 lg:pt-4">
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
      {h && h.videos.length > 0 && (
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
        {h?.sections.map((section, i) => {
          const list = cards(section.results);
          return (
            <section key={section.category.id} aria-label={section.category.name}>
              <SectionHeading title={section.category.name} href={section.category.path} env={view} />
              {i % 2 === 0 ? (
                <div className="grid grid-cols-1 gap-x-8 gap-y-6 lg:grid-cols-12">
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
