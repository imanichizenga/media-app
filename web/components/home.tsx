import { LeadCard, LiveRail, SectionHeading, StoryCard } from "@news/ui/news";
import { type Home, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { graph, organization, website } from "@/lib/seo";
import { cards, isBreaking, viewOf } from "@/lib/view";
import { Frame, Wide } from "./frame";
import { JsonLd } from "./json-ld";
import { type Maybe, none, Rail, River, Rows, Strip } from "./parts";

/**
 * Without data it is its own skeleton. Breaking news and the live rail are never bones: the skeleton is told them
 * (`known`), from the same cached answer as Home, so nothing is put above the news when it arrives (V2).
 */
export async function HomeView({
  locale,
  h,
  known,
}: {
  locale: Locale;
  h?: Home;
  known?: Pick<Home, "breaking" | "live">;
}) {
  const site = await readSite();
  const view = viewOf(locale, site);
  const t = words(locale);
  const told = h ?? known;
  const hot = told?.breaking.find((c) => isBreaking(c, view.now));
  const lead: Maybe[] = h ? cards(h.lead.filter((c) => c.id !== hot?.id)) : none(5);
  const latest: Maybe[] = h ? cards(h.latest.filter((c) => c.id !== hot?.id)) : none(7);
  const path = at(locale, "/");
  return (
    <Frame
      locale={locale}
      path={path}
      place="home"
      view={view}
      breaking={told ? cards(told.breaking.filter((c) => isBreaking(c, view.now))) : undefined}
      other={at(locale === "sw" ? "en" : "sw", "/")}
    >
      <JsonLd data={graph(organization(site, locale), website(site, locale))} />
      <h1 className="sr-only">{site.identity.brand_name}</h1>
      <Wide className="lg:pt-4">
        {told && (
          <LiveRail
            cards={cards(told.live)}
            // The day's stories after the live ones: the lead, then the newest, each once, with a picture.
            stories={
              h
                ? cards([...h.lead, ...h.latest])
                    .filter((c, i, all) => c.image && all.findIndex((x) => x.id === c.id) === i)
                    .slice(0, 14)
                : []
            }
            env={view}
            title={t("storiesRail")}
            back={t("back")}
            more={t("more")}
          />
        )}
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
        {h?.sections.map((section) => (
          <section key={section.category.id} aria-label={section.category.name}>
            <SectionHeading title={section.category.name} href={section.category.path} env={view} />
            <Rail
              list={cards(section.results)}
              env={view}
              title={section.category.name}
              href={section.category.path}
              all={t("seeAllIn", { name: section.category.name })}
              back={t("earlierStories")}
              more={t("moreStories")}
            />
          </section>
        ))}
      </Wide>
    </Frame>
  );
}
