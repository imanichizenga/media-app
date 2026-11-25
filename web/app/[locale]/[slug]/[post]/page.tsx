import type { Metadata } from "next";
import { ArticleView } from "@/components/article";
import { LiveRefresh } from "@/components/client";
import { JsonLd } from "@/components/json-ld";
import { article, orNull, site as readSite, related } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { goneOrMoved } from "@/lib/missing";
import { breadcrumbs, graph, newsArticle, videoObject } from "@/lib/seo";
import { cards, viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale; slug: string; post: string }> };

async function load({ params }: Props) {
  const { locale, slug, post } = await params;
  const path = at(locale, `/${slug}/${post}`);
  const a = (await orNull(article(locale, post, path))) ?? (await goneOrMoved(path));
  // One address for one story: the right category in the address, or it is not here.
  if (a.path !== path) await goneOrMoved(path, a.path);
  return a;
}

export async function generateMetadata(props: Props): Promise<Metadata> {
  const { locale } = await props.params;
  const [a, site] = await Promise.all([load(props), readSite()]);
  return metaOf({
    site,
    locale,
    path: a.path,
    title: a.seo.title,
    description: a.seo.description,
    others: a.translations,
    og: `/og/${locale}/${a.slug}.png?v=${Date.parse(a.modified_at).toString(36)}-${site.theme.hash}`,
    type: "article",
    article: {
      published: a.published_at,
      modified: a.modified_at,
      section: a.category.name,
      authors: a.authors.map((p) => p.path),
    },
  });
}

export default async function Page(props: Props) {
  const a = await load(props);
  const { locale } = await props.params;
  // What to read next is worth less than the story: without it the page still stands.
  const [site, next] = await Promise.all([
    readSite(),
    related(locale, a.slug).then(
      (r) => r.results,
      () => [],
    ),
  ]);
  const view = viewOf(locale, site);
  return (
    <>
      <JsonLd
        data={graph(
          newsArticle(site, a),
          ...(a.video || a.youtube_id ? [videoObject(site, a)] : []),
          breadcrumbs([
            { name: site.identity.brand_name, path: at(locale, "/") },
            ...a.breadcrumbs,
            { name: a.headline, path: a.path },
          ]),
        )}
      />
      {a.is_live && <LiveRefresh label={words(locale)("newStories")} />}
      <ArticleView
        a={a}
        env={view}
        zone={site.localization.timezone}
        related={cards(next)}
        path={a.path}
        other={a.translations[0]?.path}
      />
    </>
  );
}
