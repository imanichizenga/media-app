import type { Metadata } from "next";
import { orNull, story } from "@/lib/api";
import { ListPage, listMeta, pagingOf, type Query } from "@/lib/lists";
import { at, type Locale } from "@/lib/locale";
import { goneOrMoved } from "@/lib/missing";

type Props = { params: Promise<{ locale: Locale; slug: string }>; searchParams: Query };
async function load({ params, searchParams }: Props) {
  const [{ locale, slug }, paging] = await Promise.all([params, pagingOf(searchParams)]);
  const found =
    (await orNull(story(locale, slug, paging))) ?? (await goneOrMoved(at(locale, `/story/${slug}`)));
  const other: Locale = locale === "sw" ? "en" : "sw";
  return {
    locale,
    path: found.story.path,
    title: found.story.title,
    text: found.story.summary,
    found,
    first: !("cursor" in paging),
    others: [{ locale: other, path: at(other, `/story/${slug}`) }],
  };
}
export const generateMetadata = async (props: Props): Promise<Metadata> => listMeta(await load(props));
export default async function Page(props: Props) {
  return <ListPage {...(await load(props))} />;
}
