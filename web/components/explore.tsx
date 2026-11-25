import { Bone } from "@news/ui/base";
import { Newspaper } from "@news/ui/icons";
import { Picture } from "@news/ui/media";
import { type NewsEnv, SectionHeading } from "@news/ui/news";
import type { Card, Nav } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { CATEGORY_ICONS } from "./category-icons";
import { Frame, Wide } from "./frame";
import { none, PageHead } from "./parts";

type Face = Card["image"];
type Person = Card["authors"][number];

/** A section shows its own newest picture, as in the app. */
export function faceOf(
  n: Nav,
  stories: Card[],
  sections: { category: { id: string }; results: Card[] }[],
): Face {
  const own = sections.find((s) => s.category.id === n.id)?.results ?? [];
  const ids = new Set([n.id, ...n.children.map((c) => c.id)]);
  return (
    [...own, ...stories.filter((c) => ids.has(c.category.id))].find((c) => c.image && !c.is_sensitive)
      ?.image ?? null
  );
}
function Tile({ n, face, view }: { n?: Nav; face?: Face; view: NewsEnv }) {
  const Sign = CATEGORY_ICONS[n?.icon ?? ""] ?? Newspaper;
  if (!n) return <span aria-hidden className="bone block! h-32 w-full" />;
  return (
    <a href={n.path} className="group relative block h-32 overflow-hidden rounded-md bg-surface-sunken">
      {face && (
        <>
          <Picture
            image={face as never}
            mediaBase={view.mediaBase}
            alt=""
            sizes="(min-width: 1024px) 300px, 50vw"
            className="absolute inset-0 size-full object-cover"
          />
          <span className="absolute inset-0 bg-linear-to-t from-black/85 via-black/40 to-transparent" />
        </>
      )}
      <span
        className={`absolute inset-x-0 bottom-0 flex items-center gap-2 p-3 text-title group-hover:underline ${face ? "text-white" : ""}`}
      >
        <Sign size={18} className="shrink-0" />
        <span className="min-w-0 truncate">{n.name}</span>
      </span>
    </a>
  );
}
export function ExploreView({
  locale,
  view,
  nav,
  faces,
  people,
}: {
  locale: Locale;
  view: NewsEnv;
  nav: (Nav | undefined)[];
  faces: Face[];
  people?: Person[];
}) {
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  return (
    <Frame
      locale={locale}
      path={at(locale, "/search")}
      place="explore"
      view={view}
      title={t("navExplore")}
      other={at(other, "/search")}
    >
      <Wide>
        <PageHead title={t("navExplore")} hidden />
        <ul
          className="grid grid-cols-2 gap-3 pt-4 sm:grid-cols-3 lg:grid-cols-4 lg:gap-6"
          data-page="explore"
        >
          {nav.map((n, i) => (
            <li key={n?.id ?? i}>
              <Tile n={n} face={faces[i]} view={view} />
            </li>
          ))}
        </ul>
        {people?.length !== 0 && (
          <section aria-label={t("journalists")} className="pt-12">
            <SectionHeading title={t("journalists")} env={view} />
            <ul className="-mx-4 flex gap-4 overflow-x-auto px-4 scrollbar-none">
              {(people ?? none(6)).map((p, i) => (
                <li key={p?.path ?? i} className="relative w-24 shrink-0 text-center">
                  <span className="mx-auto grid size-18 place-items-center overflow-hidden rounded-full bg-surface-sunken font-serif text-headline-m text-text-secondary">
                    {p ? p.name.slice(0, 1) : <span aria-hidden className="bone block! size-full" />}
                  </span>
                  <span className="mt-2 line-clamp-2 text-label">
                    {p ? (
                      <a href={p.path} className="after:absolute after:inset-0">
                        {p.name}
                      </a>
                    ) : (
                      <Bone className="w-full" />
                    )}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        )}
      </Wide>
    </Frame>
  );
}
