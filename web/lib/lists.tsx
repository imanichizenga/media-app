import "server-only";
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { Frame, Wide } from "@/components/frame";
import { JsonLd } from "@/components/json-ld";
import { Feed, Nothing, PageHead } from "@/components/parts";
import type { Card } from "./api";
import { site as readSite } from "./api";
import { words } from "./i18n";
import { at, type Locale } from "./locale";
import { metaOf } from "./meta";
import { breadcrumbs, graph } from "./seo";
import { cards, viewOf } from "./view";

export type Query = Promise<{ cursor?: string | string[] }>;
export async function pagingOf(query: Query) {
  const { cursor } = await query;
  const one = Array.isArray(cursor) ? cursor[0] : cursor;
  if (one && !/^[A-Za-z0-9_-]{1,200}$/.test(one)) notFound();
  return one ? { cursor: one } : {};
}
type List = {
  locale: Locale;
  path: string;
  title: string;
  text?: string;
  found: { results: Card[]; next_cursor: string | null };
  first: boolean;
  others?: { locale: string; path: string }[];
  trail?: { name: string; path: string }[];
  head?: ReactNode;
  data?: object[];
  lead?: boolean;
  place?: "home" | "video";
};
export const listMeta = async (
  l: Pick<List, "locale" | "path" | "title" | "text" | "others" | "first"> & { seoTitle?: string },
): Promise<Metadata> =>
  metaOf({
    site: await readSite(),
    locale: l.locale,
    path: l.path,
    title: l.seoTitle ?? l.title,
    description: l.text,
    others: l.others,
    // Older pages are for readers; a search engine reads the stories from the sitemap.
    index: l.first,
  });

/** A page of stories about one thing. */
export async function ListPage(l: List) {
  const site = await readSite();
  const view = viewOf(l.locale, site);
  const t = words(l.locale);
  return (
    <Frame
      locale={l.locale}
      path={l.path}
      place={l.place ?? "home"}
      view={view}
      title={l.title}
      other={l.others?.[0]?.path}
    >
      <JsonLd
        data={graph(
          breadcrumbs([
            { name: site.identity.brand_name, path: at(l.locale, "/") },
            ...(l.trail ?? []),
            { name: l.title, path: l.path },
          ]),
          ...(l.data ?? []),
        )}
      />
      <Wide>
        {l.head ?? <PageHead title={l.title} text={l.text} />}
        <Feed
          list={cards(l.found.results)}
          env={view}
          t={t}
          lead={(l.lead ?? true) && l.first && l.found.results.length > 3}
          next={l.found.next_cursor ? `${l.path}?cursor=${l.found.next_cursor}` : undefined}
          empty={<Nothing t={t} home={at(l.locale, "/")} />}
        />
      </Wide>
    </Frame>
  );
}
