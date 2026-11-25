import "server-only";
import type { Schemas } from "@news/api-client/public";
import type { Site } from "./api";
import { absolute, crops, mediaUrl } from "./seo";
import { el, urlset } from "./xml";

export type Entry = Schemas["SitemapEntry"];
const DAY = 86_400_000;
const LANGUAGE = { sw: "sw", en: "en" } as Record<string, string>;

const alternates = (e: Entry) => {
  const all = [{ locale: e.locale, path: e.path }, ...e.translations];
  if (all.length < 2) return "";
  const sw = all.find((a) => a.locale === "sw");
  return [...all, ...(sw ? [{ locale: "x-default", path: sw.path }] : [])]
    .map((a) => `<xhtml:link rel="alternate" hreflang="${a.locale}" href="${absolute(a.path)}"/>`)
    .join("");
};

/** Stories of one month. */
export const storiesMap = (list: Entry[]) =>
  urlset(
    ["xhtml"],
    list.map(
      (e) => `<url>${el("loc", absolute(e.path))}${el("lastmod", e.modified_at)}${alternates(e)}</url>`,
    ),
  );

/** Google News: the last 48 hours, 1000 at most. The API has already cut; the clock here cuts again. */
export const newsMap = (site: Site, list: Entry[], now: number) =>
  urlset(
    ["news"],
    list
      .filter((e) => Date.parse(e.published_at) > now - 2 * DAY && Date.parse(e.published_at) <= now + 60_000)
      .slice(0, 1000)
      .map(
        (e) =>
          `<url>${el("loc", absolute(e.path))}<news:news><news:publication>${el("news:name", site.identity.brand_name)}${el("news:language", LANGUAGE[e.locale] ?? "sw")}</news:publication>${el("news:publication_date", e.published_at)}${el("news:title", e.headline)}</news:news></url>`,
      ),
  );

export const imagesMap = (site: Site, list: Entry[]) =>
  urlset(
    ["image"],
    list
      .filter((e) => e.image && !e.is_sensitive)
      .map(
        (e) =>
          `<url>${el("loc", absolute(e.path))}${crops(site, e.image)
            .map((c) => `<image:image>${el("image:loc", c)}</image:image>`)
            .join("")}</url>`,
      ),
  );

/** Google wants a title, a description, a picture and somewhere the video plays. */
export const videosMap = (site: Site, list: Entry[]) =>
  urlset(
    ["video"],
    list
      .map((e) => {
        const thumb =
          crops(site, e.image)[0] ??
          (e.video?.poster
            ? mediaUrl(site, e.video.poster)
            : e.youtube_id
              ? `https://i.ytimg.com/vi/${e.youtube_id}/hqdefault.jpg`
              : "");
        const plays = e.video
          ? el("video:content_loc", mediaUrl(site, e.video.hls))
          : e.youtube_id
            ? el("video:player_loc", `https://www.youtube-nocookie.com/embed/${e.youtube_id}`)
            : "";
        if (!thumb || !plays) return "";
        const seconds = e.duration_ms
          ? Math.min(28_800, Math.max(1, Math.round(e.duration_ms / 1000)))
          : null;
        return `<url>${el("loc", absolute(e.path))}<video:video>${el("video:thumbnail_loc", thumb)}${el("video:title", e.headline.slice(0, 100))}${el("video:description", (e.standfirst || e.headline).slice(0, 2048))}${plays}${el("video:duration", seconds)}${el("video:publication_date", e.published_at)}${el("video:family_friendly", e.is_sensitive ? "no" : "yes")}</video:video></url>`;
      })
      .filter(Boolean),
  );
