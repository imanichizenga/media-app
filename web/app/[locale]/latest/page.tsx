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
async function load({ params, searchParams }: Props) {
  const [{ locale }, paging] = await Promise.all([params, pagingOf(searchParams)]);
  return {
    ...about(locale),
    hidden: true,
    found: await latest(locale, paging),
    first: !("cursor" in paging),
  };
}
export const generateMetadata = async (props: Props): Promise<Metadata> => listMeta(await load(props));
export default async function Page(props: Props) {
  return <ListPage {...(await load(props))} />;
}
