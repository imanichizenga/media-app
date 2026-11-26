import { ArticleBody } from "@news/ui/content";
import type { Metadata } from "next";
import { Frame, Wide } from "@/components/frame";
import { JsonLd } from "@/components/json-ld";
import { PageHead, Subsections } from "@/components/parts";
import { category, orNull, page, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { ListPage, listMeta, pagingOf, type Query } from "@/lib/lists";
import { at, type Locale, PAGE_KEYS } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { goneOrMoved } from "@/lib/missing";
import { breadcrumbs, graph, organization } from "@/lib/seo";
import { contentOf, dateOf, viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale; slug: string }>; searchParams: Query };
const isStill = (slug: string) => (PAGE_KEYS as readonly string[]).includes(slug);

// ---- a category ----
async function load({ params, searchParams }: Props) {
  const [{ locale, slug }, paging] = await Promise.all([params, pagingOf(searchParams)]);
  const found = (await orNull(category(locale, slug, paging))) ?? (await goneOrMoved(at(locale, `/${slug}`)));
  const c = found.category;
  return {
    locale,
    path: c.path,
    title: c.name,
    seoTitle: c.seo_title,
    text: c.description,
    seoText: c.seo_description,
    found,
    first: !("cursor" in paging),
    others: c.translations,
    hidden: c.parents.length === 0,
    trail: c.parents,
    section: c.parents[0]?.path ?? c.path,
    rss: `/rss${locale === "en" ? "/en" : ""}/${c.slug}`,
    head: (
      <PageHead title={c.name} text={c.description} hidden={c.parents.length === 0}>
        {c.children.length > 0 && <Subsections items={c.children} />}
      </PageHead>
    ),
  };
}

// ---- the publisher's own pages ----
async function pageOf({ params }: Props) {
  const { locale, slug } = await params;
  return (await orNull(page(locale, slug))) ?? (await goneOrMoved(at(locale, `/${slug}`)));
}
async function Still(props: Props) {
  const { locale } = await props.params;
  const [site, p] = await Promise.all([readSite(), pageOf(props)]);
  const view = viewOf(locale, site);
  const t = words(locale);
  return (
    <Frame locale={locale} path={p.path} view={view} title={p.title} other={p.translations[0]?.path}>
      <JsonLd
        data={graph(
          organization(site, locale),
          breadcrumbs([
            { name: site.identity.brand_name, path: at(locale, "/") },
            { name: p.title, path: p.path },
          ]),
        )}
      />
      <Wide>
        <article className="mx-auto max-w-[44rem] pb-10" data-page="still">
          <PageHead title={p.title} text={p.summary} />
          <p className="border-border border-b pb-4 text-caption text-text-secondary">
            {t("updatedAt")}{" "}
            <time dateTime={p.modified_at}>{dateOf(p.modified_at, locale, site.localization.timezone)}</time>
          </p>
          <div className="reads pt-6">
            <ArticleBody document={p.body} context={contentOf(p, view)} />
          </div>
        </article>
      </Wide>
    </Frame>
  );
}

export async function generateMetadata(props: Props): Promise<Metadata> {
  const { locale, slug } = await props.params;
  if (!isStill(slug)) return listMeta(await load(props));
  const p = await pageOf(props);
  return metaOf({
    site: await readSite(),
    locale,
    path: p.path,
    title: p.title,
    description: p.summary,
    others: p.translations,
  });
}

export default async function Page(props: Props) {
  const { slug } = await props.params;
  return isStill(slug) ? <Still {...props} /> : <ListPage {...(await load(props))} />;
}
