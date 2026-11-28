import { cx } from "@news/ui/base";
import {
  ArrowLeft,
  Bookmark,
  ChevronLeft,
  ChevronRight,
  CircleUser,
  Compass,
  House,
  type Icon,
  Play,
  Search,
} from "@news/ui/icons";
import { type CardData, type NewsEnv, Wordmark } from "@news/ui/news";
import type { ReactNode } from "react";
import type { Nav, Site } from "@/lib/api";
import { authMethods, home, navigation, pages, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, bare, type Locale } from "@/lib/locale";
import { cards, isBreaking } from "@/lib/view";
import { AuthSheet, ReadersSheet } from "./account";
import { Breaking } from "./breaking";
import { NotifyButton, OpenInApp } from "./client";

/** What is breaking now, from Home's answer (kept a minute); a failure there costs a page nothing. */
async function breakingNow(locale: Locale, now: number): Promise<CardData[]> {
  try {
    return cards((await home(locale)).breaking.filter((c) => isBreaking(c, now)));
  } catch {
    return [];
  }
}

type Place = "home" | "video" | "explore" | "saved" | "you";
const ICON = "tap grid w-11 place-items-center rounded-sm hover:bg-current/10";
const PLACES: [
  Place,
  Icon,
  string,
  "navHome" | "navVideo" | "navExplore" | "navSaved" | "navYou",
  boolean,
][] = [
  ["home", House, "/", "navHome", true],
  ["video", Play, "/video", "navVideo", true],
  ["explore", Compass, "/search", "navExplore", false],
  ["saved", Bookmark, "/saved", "navSaved", true],
  ["you", CircleUser, "/profile", "navYou", false],
];
export const Wide = ({ children, className }: { children: ReactNode; className?: string }) => (
  <div className={cx("mx-auto max-w-7xl px-4", className)}>{children}</div>
);
export const logoOf = (site: Site) => ({
  name: site.identity.brand_name,
  light: site.identity.wordmark_light as never,
  dark: site.identity.wordmark_dark as never,
});

/**
 * The brand's mark, beside its name on every page: the symbol uploaded in the admin, or, until there is one, a
 * monogram of the name in the theme's own colours (globals.css). Both come from the database.
 */
export function BrandMark({ site, size = 32 }: { site: Site; size?: number }) {
  const symbol = site.identity.symbol;
  if (symbol)
    return (
      <img
        src={symbol.svg || symbol.png["1x"]}
        srcSet={symbol.svg ? undefined : ["1x", "2x", "3x"].map((d) => `${symbol.png[d]} ${d}`).join(", ")}
        alt=""
        width={size}
        height={size}
        className="shrink-0 rounded-md object-contain"
        style={{ width: size, height: size }}
      />
    );
  return (
    <span
      aria-hidden
      className="brand-mark grid shrink-0 place-items-center rounded-lg font-bold font-serif text-on-brand"
      style={{ width: size, height: size, fontSize: size * 0.58 }}
    >
      {site.identity.brand_name.trim().slice(0, 1).toUpperCase()}
    </span>
  );
}

export function SavedCount({ say }: { say: string }) {
  // Kept in this browser (islands/store.ts), so the island fills it; absolute, so its arrival moves nothing.
  return (
    <span
      data-saved-count
      data-say={say}
      hidden
      className="saved-count pointer-events-none absolute -top-1 left-1/2 ml-1.5 grid h-[18px] min-w-[18px] place-items-center rounded-full bg-brand px-1 font-semibold text-[11px] text-on-brand leading-none tabular-nums ring-2 ring-bg"
    >
      <span aria-hidden data-n />
      <span className="sr-only" data-said />
    </span>
  );
}

/** The signed-in reader's initial over the You place (islands/account.ts); absolute, so it moves nothing. */
const Me = () => (
  <span
    data-me-initial
    data-me-badge
    hidden
    className="absolute inset-0 -m-0.5 grid place-items-center rounded-full bg-brand font-semibold text-[12px] text-on-brand"
  />
);

/** The five places, at the foot of a phone. */
export function Places({
  locale,
  place,
  onDark = false,
}: {
  locale: Locale;
  place?: Place;
  onDark?: boolean;
}) {
  const t = words(locale);
  return (
    <nav aria-label={t("places")}>
      <ul className="flex">
        {PLACES.map(([key, Sign, path, name, solid]) => {
          const on = key === place;
          return (
            <li key={key} className="min-w-0 flex-1">
              <a
                href={at(locale, path)}
                aria-current={on ? "page" : undefined}
                className={cx(
                  "flex h-14 flex-col items-center justify-center gap-0.5 text-caption",
                  onDark
                    ? on
                      ? "font-medium text-white"
                      : "text-white/75"
                    : on
                      ? "font-medium text-nav-active"
                      : "text-nav-fg",
                )}
              >
                <span className="relative">
                  <Sign
                    size={22}
                    fill={on && solid ? "currentColor" : "none"}
                    strokeWidth={on ? 2.2 : 1.75}
                  />
                  {key === "saved" && <SavedCount say={t("savedCount", { n: "#" })} />}
                  {key === "you" && <Me />}
                </span>
                <span className="max-w-full truncate">{t(name)}</span>
              </a>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

/** For you, the latest, the sections: one row, with the mark under the open one (N3). */
function Row({
  locale,
  nav,
  here,
  quiet,
}: {
  locale: Locale;
  nav: Nav[];
  here: string;
  /** On a phone the row belongs to Home and its tabs (N3): elsewhere it would crowd out the news. */
  quiet: boolean;
}) {
  const t = words(locale);
  const tabs: [string, string][] = [
    [at(locale, "/"), t("forYou")],
    [at(locale, "/latest"), t("latest")],
    ...nav.map((n): [string, string] => [n.path, n.name]),
  ];
  return (
    <nav
      aria-label={t("categories")}
      data-row
      data-quiet={quiet ? "" : undefined}
      className={cx("relative border-border border-b bg-bg", quiet && "max-lg:hidden")}
    >
      {/* More sections than the row shows: the side with more fades, and a chevron there goes on (islands/site.ts). */}
      <div data-tabs="" className="relative mx-auto max-w-7xl">
        <ul className="flex h-12 overflow-x-auto px-1 scrollbar-none lg:justify-center-safe">
          {tabs.map(([path, name]) => (
            <li key={path} className="shrink-0">
              <a
                href={path}
                aria-current={here === path ? "page" : undefined}
                className={cx(
                  "inline-flex h-12 items-center whitespace-nowrap border-b-3 px-3 text-label",
                  here === path
                    ? "border-brand-text font-semibold text-text-primary"
                    : "border-transparent text-text-secondary hover:text-text-primary",
                )}
              >
                {name}
              </a>
            </li>
          ))}
        </ul>
        {(
          [
            [-1, t("earlierTabs"), ChevronLeft, "left-0"],
            [1, t("moreTabs"), ChevronRight, "right-0"],
          ] as const
        ).map(([way, label, Sign, side]) => (
          <button
            key={way}
            type="button"
            data-tabs-go={way}
            aria-label={label}
            hidden
            className={cx("tabs-go absolute inset-y-0 w-11 place-items-center text-text-secondary", side)}
          >
            <Sign size={20} />
          </button>
        ))}
      </div>
    </nav>
  );
}

export async function Frame({
  locale,
  path,
  place,
  view,
  breaking,
  back,
  bottom,
  title,
  section,
  reading = false,
  children,
}: {
  locale: Locale;
  path: string;
  place?: Place;
  /** The same page in the other language, when there is one (its link is in You → Language now). */
  other?: string;
  view: NewsEnv;
  /** Breaking news; without it the frame asks for it itself, so every page shows it first. */
  breaking?: CardData[];
  /** On a phone, an arrow back: to where one came from, or else here. Places of the foot have none. */
  back?: string;
  /** Instead of the places, as the article's actions are. */
  bottom?: ReactNode;
  /** On a phone the masthead is Home's alone: other places show their own name (S2). */
  title?: ReactNode;
  /** The tab to mark, when the page is not one itself. */
  section?: string;
  /** The foot gives way while one reads on. */
  reading?: boolean;
  children: ReactNode;
}) {
  const [site, nav, foot, hot, ways] = await Promise.all([
    readSite(),
    navigation(locale),
    pages(locale),
    breaking ?? breakingNow(locale, view.now),
    authMethods(),
  ]);
  const t = words(locale);
  const front =
    (path !== "" && bare(path) === "/") || bare(path) === "/latest" || nav.some((n) => n.path === path);
  // The places of the foot are where one goes back to; everything else has a way back on a phone.
  const tab = PLACES.some(([, , p]) => at(locale, p) === path);
  const backTo = back ?? (front || tab ? undefined : at(locale, "/"));
  // A breaking story's own page does not announce itself.
  const news = hot.filter((c) => c.path !== path);
  const logo = logoOf(site);
  return (
    <div className="flex min-h-dvh flex-col" data-reading-page={reading ? "" : undefined}>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:bg-bg focus:p-3"
      >
        {t("skipToNews")}
      </a>
      {/* The top stays (sticky, so it keeps its room and nothing moves); on a phone the row of sections slides
          behind the masthead while one reads down, and comes back on the way up (globals.css, islands/site.ts). */}
      <div data-top className="sticky top-0 z-40">
        <header className="relative z-10 border-masthead-rule border-b-2 bg-masthead-bg text-masthead-fg">
          <div className="mx-auto flex h-14 max-w-7xl items-center gap-1 px-4 lg:grid lg:h-20 lg:grid-cols-[1fr_auto_1fr]">
            <p className="hidden text-caption text-nav-fg lg:block">
              {new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "sw", {
                dateStyle: "full",
                timeZone: site.localization.timezone,
              }).format(view.now)}
            </p>
            {backTo && (
              <a href={backTo} data-back aria-label={t("back")} className={cx(ICON, "-ml-3 lg:hidden")}>
                <ArrowLeft size={22} />
              </a>
            )}
            <div className="min-w-0 flex-1 truncate lg:text-center">
              {title && !front ? (
                <>
                  <p className="flex min-w-0 items-center gap-2 lg:hidden">
                    {!backTo && (
                      <a
                        href={at(locale, "/")}
                        aria-label={site.identity.brand_name}
                        className="tap -ml-2 grid w-11 shrink-0 place-items-center"
                      >
                        <BrandMark site={site} size={26} />
                      </a>
                    )}
                    <span className="truncate font-serif text-headline-s">{title}</span>
                  </p>
                  <a
                    href={at(locale, "/")}
                    className="inline-flex items-center gap-3 max-lg:hidden lg:text-headline-l"
                  >
                    <BrandMark site={site} size={40} />
                    <Wordmark {...logo} />
                  </a>
                </>
              ) : (
                <a
                  href={at(locale, "/")}
                  className="inline-flex max-w-full items-center gap-2 text-headline-m lg:gap-3 lg:text-headline-l"
                >
                  <BrandMark site={site} size={30} />
                  <Wordmark {...logo} className="truncate" />
                </a>
              )}
            </div>
            <div className="flex justify-end">
              {/* Search first: it is what readers come back for (ADR-0051). On its own page it is the field. */}
              {place !== "explore" && (
                <a href={at(locale, "/search?focus=1")} aria-label={t("searchOpen")} className={ICON}>
                  <Search size={20} />
                </a>
              )}
              {/* At a desk there is no bar at the foot: its places for one's own things are here. */}
              <a
                href={at(locale, "/saved")}
                aria-label={t("navSaved")}
                aria-current={place === "saved" ? "page" : undefined}
                className={cx(ICON, "max-lg:hidden")}
              >
                <span className="relative">
                  <Bookmark size={20} />
                  <SavedCount say={t("savedCount", { n: "#" })} />
                </span>
              </a>
              {/* The language and light or dark are the reader's settings (You); the bell is here. */}
              {/* Desk order: search, saved, bell, then the reader's own profile last. */}
              <NotifyButton t={t} />
              <a
                href={at(locale, "/profile")}
                aria-label={t("navYou")}
                aria-current={place === "you" ? "page" : undefined}
                className={cx(ICON, "max-lg:hidden")}
              >
                <span className="relative">
                  <CircleUser size={20} />
                  <Me />
                </span>
              </a>
            </div>
          </div>
        </header>
        {/* Part of the frame: known before the page is, so nothing pushes the page down later (V2). */}
        <Row locale={locale} nav={nav} here={section ?? path} quiet={!front} />
      </div>
      <Breaking list={news} env={view} t={t} />
      <main id="main" className="flex-1 pb-24 lg:pb-16">
        {children}
      </main>
      <AuthSheet t={t} methods={ways} brand={site.identity.brand_name} />
      <ReadersSheet t={t} />
      <footer className="border-border border-t bg-surface max-lg:pb-20">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 py-8">
          <div className="flex items-center gap-3">
            <BrandMark site={site} size={44} />
            <div>
              <p className="font-serif text-headline-s">{site.identity.brand_name}</p>
              <p className="text-caption text-text-secondary">
                {locale === "en" ? site.identity.tagline_en : site.identity.tagline_sw}
              </p>
            </div>
          </div>
          <ul className="flex flex-wrap gap-x-6 text-label text-text-secondary">
            {foot.results.map((p) => (
              <li key={p.key}>
                <a href={p.path} className="tap inline-flex items-center hover:text-text-primary">
                  {p.title}
                </a>
              </li>
            ))}
          </ul>
        </div>
      </footer>
      {site.apps.android && !reading && (
        <OpenInApp href={site.apps.android} text={t("openInApp")} action={t("open")} close={t("close")} />
      )}
      <div
        className={cx(
          "hides fixed inset-x-0 bottom-0 z-30 border-border border-t pb-[env(safe-area-inset-bottom)] lg:hidden",
          bottom ? "bg-surface" : "bg-nav-bg",
        )}
        data-bar
      >
        {bottom ?? <Places locale={locale} place={place} />}
      </div>
    </div>
  );
}
