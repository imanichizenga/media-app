import type { Metadata } from "next";
import { VideoView } from "@/components/video";
import { byType, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { pagingOf, type Query } from "@/lib/lists";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { cards } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }>; searchParams: Query };
export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  const { locale } = await params;
  const other: Locale = locale === "sw" ? "en" : "sw";
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/video"),
    title: words(locale)("videos"),
    others: [{ locale: other, path: at(other, "/video") }],
    index: !("cursor" in (await pagingOf(searchParams))),
  });
}
export default async function Page(props: Props) {
  const [{ locale }, paging] = await Promise.all([props.params, pagingOf(props.searchParams)]);
  const found = await byType(locale, "video", paging);
  return (
    <VideoView
      locale={locale}
      list={cards(found.results)}
      next={found.next_cursor ? `${at(locale, "/video")}?cursor=${found.next_cursor}` : undefined}
    />
  );
}
