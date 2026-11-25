import { Designed } from "@news/ui/news";
import type { Metadata } from "next";
import { JsonLd } from "@/components/json-ld";
import { BUTTON } from "@/components/parts";
import { type Short, ShortsFeed, ShortsFrame } from "@/components/shorts";
import { byType, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { graph, mediaUrl, videoObject } from "@/lib/seo";
import { agoOf, viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }> };
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const other: Locale = locale === "sw" ? "en" : "sw";
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/shorts"),
    title: words(locale)("shorts"),
    others: [{ locale: other, path: at(other, "/shorts") }],
  });
}

async function Loaded({ locale }: { locale: Locale }) {
  const [site, found] = await Promise.all([readSite(), byType(locale, "short", { limit: 20 })]);
  const view = viewOf(locale, site);
  const t = words(locale);
  const list: Short[] = found.results
    .filter((c) => c.video && !c.is_sensitive)
    .map((c) => ({
      id: c.id,
      path: c.path,
      headline: c.headline,
      category: c.category.name,
      when: agoOf(c.published_at, view),
      at: c.published_at,
      hls: mediaUrl(site, c.video?.hls ?? ""),
      poster: c.video?.poster ? mediaUrl(site, c.video.poster) : "",
    }));
  if (list.length === 0)
    return (
      <div className="grid flex-1 place-items-center [--color-surface-sunken:#222]">
        <Designed
          kind="empty"
          title={t("feedEmptyTitle")}
          body={t("feedEmptyBody")}
          action={
            <a href={at(locale, "/")} className={BUTTON}>
              {t("goHome")}
            </a>
          }
        />
      </div>
    );
  return (
    <>
      <JsonLd
        data={graph(
          ...found.results.filter((c) => c.video && !c.is_sensitive).map((c) => videoObject(site, c)),
        )}
      />
      <ShortsFeed
        list={list}
        words={{
          mute: t("mute"),
          unmute: t("unmute"),
          play: t("play"),
          pause: t("pause"),
          save: t("save"),
          unsave: t("unsave"),
          share: t("share"),
          shared: t("linkCopied"),
          open: t("watchFull"),
          error: t("videoError"),
        }}
      />
    </>
  );
}
export default async function Page({ params }: Props) {
  const { locale } = await params;
  return (
    <ShortsFrame locale={locale}>
      <Loaded locale={locale} />
    </ShortsFrame>
  );
}
