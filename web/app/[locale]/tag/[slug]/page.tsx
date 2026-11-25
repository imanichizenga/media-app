import type { Metadata } from "next";
import { orNull, tag } from "@/lib/api";
import { ListPage, listMeta, pagingOf, type Query } from "@/lib/lists";
import { at, type Locale } from "@/lib/locale";
import { goneOrMoved } from "@/lib/missing";

type Props = { params: Promise<{ locale: Locale; slug: string }>; searchParams: Query };
async function load({ params, searchParams }: Props) {
  const [{ locale, slug }, paging] = await Promise.all([params, pagingOf(searchParams)]);
  const found =
    (await orNull(tag(locale, slug, paging))) ?? (await goneOrMoved(at(locale, `/tag/${slug}`)));
  const other: Locale = locale === "sw" ? "en" : "sw";
  return {
    locale,
    path: found.tag.path,
    title: found.tag.name,
    found,
    first: !("cursor" in paging),
    others: [{ locale: other, path: at(other, `/tag/${slug}`) }],
  };
}
export const generateMetadata = async (props: Props): Promise<Metadata> => listMeta(await load(props));
export default async function Page(props: Props) {
  return ListPage(await load(props));
}
