import type { Metadata } from "next";
import { latest } from "@/lib/api";
import { words } from "@/lib/i18n";
import { ListPage, listMeta, pagingOf, type Query } from "@/lib/lists";
import { at, type Locale } from "@/lib/locale";

type Props = { params: Promise<{ locale: Locale }>; searchParams: Query };
const about = (locale: Locale) => {
  const other: Locale = locale === "sw" ? "en" : "sw";
  return {
    locale,
    path: at(locale, "/latest"),
    title: words(locale)("latest"),
    others: [{ locale: other, path: at(other, "/latest") }],
  };
};
export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  const { locale } = await params;
  return listMeta({ ...about(locale), first: !("cursor" in (await pagingOf(searchParams))) });
}
export default async function Page({ params, searchParams }: Props) {
  const { locale } = await params;
  const paging = await pagingOf(searchParams);
  return ListPage({
    ...about(locale),
    found: await latest(locale, paging),
    first: !("cursor" in paging),
  });
}
