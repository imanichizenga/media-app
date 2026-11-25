import { LeadCard, VideoCard } from "@news/ui/news";
import { site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { breadcrumbs, graph } from "@/lib/seo";
import { viewOf } from "@/lib/view";
import { Frame, Wide } from "./frame";
import { JsonLd } from "./json-ld";
import { type Maybe, More, Nothing, PageHead } from "./parts";
import { VideoTabs } from "./video-tabs";

export async function VideoView({ locale, list, next }: { locale: Locale; list: Maybe[]; next?: string }) {
  const site = await readSite();
  const view = viewOf(locale, site);
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  const path = at(locale, "/video");
  return (
    <Frame
      locale={locale}
      path={path}
      place="video"
      view={view}
      title={t("navVideo")}
      other={at(other, "/video")}
    >
      <JsonLd
        data={graph(
          breadcrumbs([
            { name: site.identity.brand_name, path: at(locale, "/") },
            { name: t("videos"), path },
          ]),
        )}
      />
      <Wide>
        <PageHead title={t("videos")} hidden />
        <VideoTabs locale={locale} open="video" />
        {list.length === 0 ? (
          <Nothing t={t} home={at(locale, "/")} />
        ) : (
          <div data-page="video">
            <div className="grid grid-cols-1 gap-x-8 gap-y-8 lg:grid-cols-12 lg:pt-4">
              <LeadCard card={list[0]} env={view} priority play className="lg:col-span-8" />
              <ul className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:col-span-4 lg:flex lg:flex-col">
                {list.slice(1, 4).map((card, i) => (
                  <li key={card?.id ?? i} className="min-w-0">
                    <VideoCard card={card} env={view} />
                  </li>
                ))}
              </ul>
            </div>
            <ul className="grid grid-cols-1 gap-x-6 gap-y-8 pt-8 sm:grid-cols-2 lg:grid-cols-4 lg:pt-10">
              {list.slice(4).map((card, i) => (
                <li key={card?.id ?? i} className="min-w-0">
                  <VideoCard card={card} env={view} />
                </li>
              ))}
            </ul>
            <More href={next} t={t} />
          </div>
        )}
      </Wide>
    </Frame>
  );
}
