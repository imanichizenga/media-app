import { ArticleBody } from "@news/ui/content";
import type { Metadata } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import { type Article, site as readSite } from "@/lib/api";
import { env } from "@/lib/env";
import { internalToken } from "@/lib/internal";
import type { Locale } from "@/lib/locale";
import { contentOf, viewOf } from "@/lib/view";

export const dynamic = "force-dynamic";
export const metadata: Metadata = { robots: { index: false, follow: false }, title: "" };

type Props = { params: Promise<{ locale: Locale; post: string }> };

/**
 * The whole of a story for subscribers, drawn as its page draws it, for app/api/subscribe only (ADR-0052). Asked for
 * by this server with its internal token and the reader's access token; for anyone else it is not here.
 */
export default async function Page({ params }: Props) {
  const { locale, post } = await params;
  const h = await headers();
  const access = h.get("x-reader-access") ?? "";
  if (h.get("x-internal") !== internalToken(env.revalidateSecret) || !access || !/^[0-9a-f-]{36}$/.test(post))
    notFound();
  const res = await fetch(`${env.api}/api/v1/subscriptions/posts/${post}?locale=${locale}`, {
    cache: "no-store",
    headers: { authorization: `Bearer ${access}` },
    signal: AbortSignal.timeout(10_000),
  });
  if (res.status !== 200) notFound();
  const article = (await res.json()) as Article;
  const view = viewOf(locale, await readSite());
  return (
    <>
      <div id="full-body">
        <ArticleBody document={article.body} context={contentOf(article, view)} />
      </div>
      <i id="full-end" hidden />
    </>
  );
}
