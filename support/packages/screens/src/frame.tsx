import { type CardData, type Logo, type NewsEnv, Wordmark } from "@news/ui/news";
import { cx } from "@news/ui/primitives";
import { Bookmark, CircleUser, Compass, Home, type LucideIcon, Moon, Play, Search } from "lucide-react";
import type { ReactNode } from "react";
import en from "../data/en.json";
import sw from "../data/sw.json";
import { type Text, text } from "./text";

// biome-ignore lint/suspicious/noExplicitAny: captured API answers, checked by the API's own contract
export type Data = any;
export type Brand = { name: string; light?: Logo | null; dark?: Logo | null };
export type Page = {
  locale: "sw" | "en";
  d: Data;
  t: Text;
  env: NewsEnv;
  breaking: CardData;
  brand: Brand;
};

// The moment the content was captured, so every time on every page is fixed.
const NOW = Math.max(...(sw as Data).latest.map((c: CardData) => Date.parse(c.published_at))) + 6 * 60_000;
export function pageOf(locale: "sw" | "en", mediaBase: string, brand?: Brand): Page {
  const d = (locale === "sw" ? sw : en) as Data;
  const t = text[locale];
  const env: NewsEnv = { locale, mediaBase, now: NOW, t };
  const isBreaking = (c: CardData) => c.breaking_until !== null && Date.parse(c.breaking_until) > NOW;
  // The banner's story is not repeated below it.
  const breaking = d.home.lead.find(isBreaking) ?? d.home.lead[0];
  const lead = d.home.lead.filter((c: CardData) => c.id !== breaking.id);
  return {
    locale,
    d: { ...d, home: { ...d.home, lead } },
    t,
    env,
    breaking,
    brand: brand ?? { name: t.brand },
  };
}

const TABS: [keyof Text["nav"], LucideIcon][] = [
  ["home", Home],
  ["video", Play],
  ["explore", Compass],
  ["saved", Bookmark],
  ["you", CircleUser],
];
/** Icons whose filled form is still the icon. */
const SOLID = new Set(["home", "video", "saved"]);
const icon = "tap grid w-11 place-items-center rounded-sm hover:bg-current/10";

/** The same five places as the app, at the bottom of a phone, along the top of a desk. */
export function Frame({
  p,
  tab,
  section,
  bottom,
  children,
  bare = false,
}: {
  p: Page;
  tab: keyof Text["nav"];
  section?: string;
  /** Replaces the tab bar on phones, as the article's action bar does. */
  bottom?: ReactNode;
  children: ReactNode;
  bare?: boolean;
}) {
  const { t, d } = p;
  return (
    <div className="flex min-h-dvh flex-col">
      <a href="#main" className="sr-only focus:not-sr-only">
        {t.nav.home}
      </a>
      <header className="sticky top-0 z-20 border-masthead-rule border-b-2 bg-masthead-bg text-masthead-fg lg:static">
        <div className="mx-auto flex h-14 max-w-7xl items-center gap-2 px-4 lg:grid lg:h-20 lg:grid-cols-3">
          <p className="hidden text-caption text-nav-fg lg:block">{t.date}</p>
          <a href="home.html" className="flex-1 text-headline-m lg:text-center lg:text-headline-l">
            <Wordmark {...p.brand} />
          </a>
          <div className="flex justify-end">
            <a href="search.html" aria-label={t.search} className={icon}>
              <Search aria-hidden size={20} />
            </a>
            <button type="button" aria-label={t.otherLanguageLabel} className={cx(icon, "text-label")}>
              {t.otherLanguage}
            </button>
            <button type="button" aria-label={t.theme} className={icon}>
              <Moon aria-hidden size={20} />
            </button>
          </div>
        </div>
        {!bare && (
          <nav aria-label={t.categories} className="lg:border-current/10 lg:border-t">
            <ul className="mx-auto flex max-w-7xl gap-1 overflow-x-auto px-2 scrollbar-none lg:justify-center">
              {d.navigation.map((n: { id: string; name: string; path: string }) => (
                <li key={n.id}>
                  <a
                    href="category.html"
                    aria-current={section === n.name ? "page" : undefined}
                    className={cx(
                      "tap inline-flex items-center whitespace-nowrap border-b-2 px-3 text-label",
                      section === n.name
                        ? "border-nav-active font-semibold text-masthead-fg"
                        : "border-transparent text-nav-fg hover:text-masthead-fg",
                    )}
                  >
                    {n.name}
                  </a>
                </li>
              ))}
            </ul>
          </nav>
        )}
      </header>
      <main id="main" className="flex-1 pb-20 lg:pb-16">
        {children}
      </main>
      <footer className="hidden border-border border-t bg-surface lg:block">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 py-8">
          <p className="font-serif text-headline-s">{p.brand.name}</p>
          <ul className="flex flex-wrap gap-6 text-label text-text-secondary">
            {t.footer.map((name) => (
              <li key={name}>{name}</li>
            ))}
          </ul>
        </div>
      </footer>
      <div
        className={cx(
          "fixed inset-x-0 bottom-0 z-20 border-border border-t pb-[env(safe-area-inset-bottom)] lg:hidden",
          bottom ? "bg-surface" : "bg-nav-bg",
        )}
      >
        {bottom ?? <Tabs t={t} tab={tab} />}
      </div>
    </div>
  );
}
export const Tabs = ({
  t,
  tab,
  onDark = false,
  side = false,
}: {
  t: Text;
  tab: keyof Text["nav"];
  onDark?: boolean;
  /** A rail at the left edge instead of a bar at the bottom. */
  side?: boolean;
}) => (
  <nav>
    <ul className={cx("flex", side && "flex-col gap-2")}>
      {TABS.map(([key, Icon]) => {
        const on = key === tab;
        return (
          <li key={key} className="flex-1">
            <a
              href={key === "video" ? "shorts.html" : "home.html"}
              aria-current={on ? "page" : undefined}
              className={cx(
                "relative flex h-14 flex-col items-center justify-center text-caption",
                onDark
                  ? on
                    ? "font-medium text-white"
                    : "text-white/75"
                  : on
                    ? "font-medium text-nav-active"
                    : "text-nav-fg",
              )}
            >
              <Icon
                aria-hidden
                size={22}
                fill={on && SOLID.has(key) ? "currentColor" : "none"}
                strokeWidth={on ? 2.25 : 1.75}
              />
              {t.nav[key]}
            </a>
          </li>
        );
      })}
    </ul>
  </nav>
);
/** The app in a wide window (D7): from 840 the places move from the bottom to a rail at the left. */
export function AppFrame({
  p,
  tab,
  bottom,
  children,
}: {
  p: Page;
  tab: keyof Text["nav"];
  bottom?: ReactNode;
  children: ReactNode;
}) {
  const { t } = p;
  return (
    <div className="min-h-dvh expanded:pl-24">
      <div className="fixed inset-y-0 left-0 z-30 hidden w-24 border-border border-r bg-nav-bg pt-20 expanded:block">
        <Tabs t={t} tab={tab} side />
      </div>
      <header className="sticky top-0 z-20 flex h-14 items-center border-masthead-rule border-b-2 bg-masthead-bg px-6 text-masthead-fg">
        <p className="flex-1 text-headline-m">
          <Wordmark {...p.brand} />
        </p>
        <a href="search.html" aria-label={t.search} className={icon}>
          <Search aria-hidden size={20} />
        </a>
      </header>
      <main id="main" className="pb-20">
        {children}
      </main>
      <div
        className={cx(
          "fixed inset-x-0 bottom-0 z-20 border-border border-t expanded:left-24",
          bottom ? "bg-surface" : "bg-nav-bg expanded:hidden",
        )}
      >
        {bottom ?? <Tabs t={t} tab={tab} />}
      </div>
    </div>
  );
}
export const Wide = ({ children, className }: { children: ReactNode; className?: string }) => (
  <div className={cx("mx-auto max-w-7xl px-4", className)}>{children}</div>
);
