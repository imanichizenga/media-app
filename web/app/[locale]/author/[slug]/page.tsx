import { Picture } from "@news/ui/media";
import type { Metadata } from "next";
import { type Article, author, orNull, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { ListPage, listMeta, pagingOf, type Query } from "@/lib/lists";
import { at, type Locale } from "@/lib/locale";
import { goneOrMoved } from "@/lib/missing";
import { absolute, crops, organization } from "@/lib/seo";

type Props = { params: Promise<{ locale: Locale; slug: string }>; searchParams: Query };
async function load({ params, searchParams }: Props) {
  const [{ locale, slug }, paging, site] = await Promise.all([params, pagingOf(searchParams), readSite()]);
  const found =
    (await orNull(author(locale, slug, paging))) ?? (await goneOrMoved(at(locale, `/author/${slug}`)));
  const a = found.author;
  const other: Locale = locale === "sw" ? "en" : "sw";
  const t = words(locale);
  return {
    locale,
    path: a.path,
    title: a.name,
    text: a.bio,
    found,
    first: !("cursor" in paging),
    lead: false,
    others: [{ locale: other, path: at(other, `/author/${slug}`) }],
    data: [
      {
        "@type": "ProfilePage",
        mainEntity: {
          "@type": "Person",
          name: a.name,
          url: absolute(a.path),
          ...(a.title ? { jobTitle: a.title } : {}),
          ...(a.bio ? { description: a.bio } : {}),
          ...(a.expertise.length ? { knowsAbout: a.expertise } : {}),
          ...(a.links.length ? { sameAs: a.links } : {}),
          ...(a.avatar ? { image: crops(site, a.avatar as Article["image"]) } : {}),
          worksFor: organization(site),
        },
      },
    ],
    head: (
      <header className="flex flex-col gap-4 border-border border-b pt-6 pb-6 sm:flex-row sm:items-start lg:pt-10">
        <span data-face className="grid size-24 shrink-0 place-items-center overflow-hidden rounded-full bg-surface-sunken font-serif text-headline-l text-text-secondary">
          {a.avatar ? (
            <Picture
              image={a.avatar as never}
              mediaBase={site.media_base_url}
              alt=""
              sizes="96px"
              className="size-full object-cover"
            />
          ) : (
            a.name.slice(0, 1)
          )}
        </span>
        <div className="flex min-w-0 flex-col gap-2">
          <h1 className="font-serif text-headline-l lg:text-display">{a.name}</h1>
          {a.title && <p className="text-label text-text-secondary">{a.title}</p>}
          {a.bio && <p className="max-w-prose text-body-l">{a.bio}</p>}
          {a.expertise.length > 0 && (
            <p className="text-label text-text-secondary">
              {t("expertise")}: {a.expertise.join(", ")}
            </p>
          )}
          {a.links.length > 0 && (
            <ul className="flex flex-wrap gap-x-4">
              {a.links.map((link) => (
                <li key={link}>
                  <a
                    href={link}
                    rel="me noopener"
                    className="tap inline-flex items-center text-link underline underline-offset-4"
                  >
                    {new URL(link).hostname}
                  </a>
                </li>
              ))}
            </ul>
          )}
        </div>
      </header>
    ),
  };
}
export const generateMetadata = async (props: Props): Promise<Metadata> => listMeta(await load(props));
export default async function Page(props: Props) {
  return <ListPage {...(await load(props))} />;
}
