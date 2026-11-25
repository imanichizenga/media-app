import "server-only";
import type { ContentContext } from "@news/ui/content";
import type { CardData, NewsEnv } from "@news/ui/news";
import { ago as agoOf } from "@news/ui/news";
import type { Article, Card, Site } from "./api";
import { words } from "./i18n";
import type { Locale } from "./locale";

/** One moment for a whole page. */
export function viewOf(locale: Locale, site: Site): NewsEnv {
  const t = words(locale);
  return {
    locale,
    mediaBase: site.media_base_url,
    now: Date.now(),
    t: {
      live: t("live"),
      breaking: t("breaking"),
      gallery: t("gallery"),
      sensitive: t("sensitive"),
      minutes: (n) => t("minutesRead", { n }),
      more: t("more"),
    },
  };
}
export const cards = (list: Card[]): CardData[] => list as CardData[];
export const isBreaking = (c: Card, now: number) =>
  c.breaking_until !== null && Date.parse(c.breaking_until) > now;

export function contentOf(
  source: { assets: Record<string, unknown>; links?: Article["links"] },
  view: NewsEnv,
): ContentContext {
  const t = words(view.locale);
  return {
    assets: source.assets as ContentContext["assets"],
    links: source.links ?? {},
    mediaBase: view.mediaBase,
    labels: {
      play: t("play"),
      playError: t("videoError"),
      sensitive: t("sensitive"),
      readAlso: t("readAlso"),
      openPost: t("openPost"),
      unsupported: t("unsupported"),
      pinned: t("pinned"),
      gallery: t("gallery"),
    },
    interactive: true,
    formatTime: (iso) => agoOf(iso, view),
  };
}
export const dateOf = (iso: string, locale: Locale, timeZone: string) =>
  new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "sw", {
    dateStyle: "long",
    timeStyle: "short",
    timeZone,
  }).format(Date.parse(iso));
export { agoOf };
