import { cx } from "@news/ui/base";
import {
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
import { BreakingBanner, type CardData, type NewsEnv, Wordmark } from "@news/ui/news";
import type { ReactNode } from "react";
import type { Nav, Site } from "@/lib/api";
import { navigation, pages, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, bare, type Locale } from "@/lib/locale";
import { OpenInApp, SchemeButton } from "./client";

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
                <Sign size={22} fill={on && solid ? "currentColor" : "none"} strokeWidth={on ? 2.2 : 1.75} />
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
      className={cx("sticky top-0 z-20 border-border border-b bg-bg lg:static", quiet && "max-lg:hidden")}
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
  other,
  view,
  breaking,
  bottom,
  title,
  section,
  reading = false,
  children,
}: {
  locale: Locale;
  path: string;
  place?: Place;
  /** The same page in the other language, when there is one. */
  other?: string;
  view: NewsEnv;
  breaking?: CardData;
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
  const [site, nav, foot] = await Promise.all([readSite(), navigation(locale), pages(locale)]);
  const t = words(locale);
  const front =
    (path !== "" && bare(path) === "/") || bare(path) === "/latest" || nav.some((n) => n.path === path);
  const logo = logoOf(site);
  const otherLocale: Locale = locale === "sw" ? "en" : "sw";
  return (
    <div className="flex min-h-dvh flex-col" data-reading-page={reading ? "" : undefined}>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:top-2 focus:left-2 focus:z-50 focus:bg-bg focus:p-3"
      >
        {t("skipToNews")}
      </a>
      <header className="border-masthead-rule border-b-2 bg-masthead-bg text-masthead-fg">
        <div className="mx-auto flex h-14 max-w-7xl items-center gap-1 px-4 lg:grid lg:h-20 lg:grid-cols-[1fr_auto_1fr]">
          <p className="hidden text-caption text-nav-fg lg:block">
            {new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "sw", {
              dateStyle: "full",
              timeZone: site.localization.timezone,
            }).format(view.now)}
          </p>
          <div className="min-w-0 flex-1 truncate lg:text-center">
            {title && !front ? (
              <>
                <p className="truncate font-serif text-headline-s lg:hidden">{title}</p>
                <a href={at(locale, "/")} className="max-lg:hidden lg:text-headline-l">
                  <Wordmark {...logo} className="lg:mx-auto" />
                </a>
              </>
            ) : (
              <a href={at(locale, "/")} className="text-headline-m lg:text-headline-l">
                <Wordmark {...logo} className="lg:mx-auto" />
              </a>
            )}
          </div>
          <div className="flex justify-end">
            <a
              href={at(locale, "/search")}
              aria-label={t("navExplore")}
              className={cx(ICON, "max-lg:hidden")}
            >
              <Search size={20} />
            </a>
            <a
              href={other ?? at(otherLocale, "/")}
              hrefLang={otherLocale}
              lang={otherLocale}
              aria-label={otherLocale === "sw" ? "Kiswahili" : "English"}
              className={cx(ICON, "text-label")}
            >
              {otherLocale.toUpperCase()}
            </a>
            <SchemeButton label={t("appearance")} />
          </div>
        </div>
      </header>
      {/* Part of the frame: known before the page is, so nothing pushes the page down later (V2). */}
      <Row locale={locale} nav={nav} here={section ?? path} quiet={!front} />
      <BreakingBanner card={breaking} env={view} />
      <main id="main" className="flex-1 pb-24 lg:pb-16">
        {children}
      </main>
      <footer className="border-border border-t bg-surface max-lg:pb-20">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 py-8">
          <p className="font-serif text-headline-s">{site.identity.brand_name}</p>
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
