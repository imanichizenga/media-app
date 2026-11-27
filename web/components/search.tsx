import { Bone, cx } from "@news/ui/base";
import { Search as Magnifier, X } from "@news/ui/icons";
import { type CardData, Designed, type NewsEnv, RowCard } from "@news/ui/news";
import type { Found, Hit } from "@/lib/api";
import type { T } from "@/lib/i18n";
import { addressOf, type Kind, SINCE, type Wanted } from "@/lib/search";
import { BUTTON } from "./button";
import { More, none } from "./parts";

/** The listbox of recent searches (islands/search.ts). */
export const SUGGEST = "search-suggest";
const CHIP = "tap inline-flex shrink-0 items-center rounded-full border px-4 text-label";

/**
 * A form that works with nothing but the browser (GET, this page's own address). The island searches as one types,
 * without a reload, and offers the searches made on this device; the chosen filters go with new words.
 */
export function SearchForm({ base, wanted, t }: { base: string; wanted: Wanted; t: T }) {
  return (
    // biome-ignore lint/a11y/useSemanticElements: <search> around a form is newer than the browsers we serve
    <form role="search" action={base} method="get" className="relative" data-search>
      <label htmlFor="q" className="sr-only">
        {t("searchLabel")}
      </label>
      <div className="flex h-12 items-center gap-1 rounded-full border border-border-strong bg-surface pr-1 pl-4 focus-within:border-text-primary lg:h-14">
        {/* While results come, the magnifier turns (globals.css). */}
        <span aria-hidden className="relative grid size-5 shrink-0 place-items-center text-text-secondary">
          <Magnifier size={20} className="search-idle" />
          <span className="search-spin absolute inset-0.5 rounded-full border-2 border-current border-t-transparent" />
        </span>
        <input
          id="q"
          name="q"
          type="search"
          defaultValue={wanted.q}
          placeholder={t("searchPlaceholder")}
          maxLength={100}
          autoComplete="off"
          autoCapitalize="off"
          spellCheck={false}
          enterKeyHint="search"
          role="combobox"
          aria-autocomplete="list"
          aria-expanded="false"
          aria-controls={SUGGEST}
          aria-describedby="search-status"
          className="h-full min-w-0 flex-1 bg-transparent text-body-l outline-none placeholder:text-text-tertiary [&::-webkit-search-cancel-button]:hidden"
        />
        <button
          type="button"
          data-search-clear
          aria-label={t("searchClear")}
          hidden={!wanted.q}
          className="tap grid w-11 shrink-0 place-items-center rounded-full text-text-secondary hover:bg-current/10"
        >
          <X size={18} />
        </button>
        <button
          type="submit"
          className="tap shrink-0 rounded-full bg-brand px-5 text-label text-on-brand hover:bg-brand-strong"
        >
          {t("searchGo")}
        </button>
      </div>
      {wanted.kind && <input type="hidden" name="kind" value={wanted.kind} />}
      {wanted.since && <input type="hidden" name="since" value={wanted.since} />}
      {wanted.sort && <input type="hidden" name="sort" value={wanted.sort} />}
      {/* What came, said to those who listen: results change as one types. */}
      <p id="search-status" role="status" className="sr-only" data-search-status />
      {/* The panel holds the listbox, and above it what is not an option: the heading of recent searches. */}
      <div
        data-suggest-panel
        hidden
        className="absolute inset-x-0 top-full z-30 mt-2 overflow-hidden rounded-md border border-border bg-surface-raised py-1 shadow-lg"
      >
        <div
          data-recent-head
          hidden
          className="flex items-center justify-between px-4 pt-1 pb-2 text-caption text-text-secondary"
        >
          <span>{t("searchRecent")}</span>
          <button type="button" data-search-forget className="tap underline">
            {t("searchClearRecent")}
          </button>
        </div>
        <div id={SUGGEST} role="listbox" aria-label={t("searchRecent")} />
      </div>
    </form>
  );
}

function Chips({ label, items }: { label: string; items: { name: string; href: string; on: boolean }[] }) {
  return (
    <ul className="flex shrink-0 gap-2" aria-label={label}>
      {items.map((c) => (
        <li key={c.href} className="shrink-0">
          <a
            href={c.href}
            aria-current={c.on ? "true" : undefined}
            rel="nofollow"
            className={cx(
              CHIP,
              c.on
                ? "border-text-primary bg-text-primary text-surface"
                : "border-border hover:bg-surface-sunken",
            )}
          >
            {c.name}
          </a>
        </li>
      ))}
    </ul>
  );
}
const Rule = () => <span aria-hidden className="my-2 w-px shrink-0 bg-border" />;

/** Filters are links: each is an address of its own, readable without JavaScript, and kept by the CDN. */
export function Filters({ base, wanted, t }: { base: string; wanted: Wanted; t: T }) {
  const kinds: [Kind | undefined, string][] = [
    [undefined, t("searchTypeAll")],
    ["stories", t("searchTypeStories")],
    ["videos", t("searchTypeVideos")],
    ["live", t("searchTypeLive")],
    ["galleries", t("searchTypeGalleries")],
  ];
  const periods: [Wanted["since"], string][] = [
    [undefined, t("searchAnyTime")],
    [SINCE[0], t("searchPastDay")],
    [SINCE[1], t("searchPastWeek")],
    [SINCE[2], t("searchPastMonth")],
    [SINCE[3], t("searchPastYear")],
  ];
  const sorts: [Wanted["sort"], string][] = [
    [undefined, t("searchSortBest")],
    ["newest", t("searchSortNewest")],
  ];
  // One row that scrolls on a phone: the results begin in the first screen (space is for news).
  return (
    <nav
      className="-mx-4 flex gap-3 overflow-x-auto px-4 pt-3 scrollbar-none lg:flex-wrap"
      aria-label={t("searchFilters")}
    >
      <Chips
        label={t("searchType")}
        items={kinds.map(([kind, name]) => ({
          name,
          href: addressOf(base, wanted, { kind }),
          on: wanted.kind === kind,
        }))}
      />
      <Rule />
      <Chips
        label={t("searchWhen")}
        items={periods.map(([since, name]) => ({
          name,
          href: addressOf(base, wanted, { since }),
          on: wanted.since === since,
        }))}
      />
      <Rule />
      <Chips
        label={t("searchSort")}
        items={sorts.map(([sort, name]) => ({
          name,
          href: addressOf(base, wanted, { sort }),
          on: wanted.sort === sort,
        }))}
      />
    </nav>
  );
}

/** The words that matched, in bold: the engine sends text and marks, never markup (ADR-0049). */
export function Snippet({ hit }: { hit: Hit }) {
  if (hit.snippet.length === 0) return null;
  return (
    <p className="line-clamp-2 pt-1 text-body-s text-text-secondary" data-snippet>
      {hit.snippet.map((s, i) =>
        s.hit ? (
          // biome-ignore lint/suspicious/noArrayIndexKey: the pieces never move
          <mark key={i} className="bg-transparent font-semibold text-text-primary">
            {s.text}
          </mark>
        ) : (
          s.text
        ),
      )}
    </p>
  );
}

export function Results({
  base,
  wanted,
  found,
  env,
  t,
}: {
  base: string;
  wanted: Wanted;
  found: Found;
  env: NewsEnv;
  t: T;
}) {
  const count = found.total_is_exact
    ? t("searchCount", { n: found.total })
    : t("searchCountMany", { n: found.total });
  return (
    <section aria-labelledby="results" className="pt-4 lg:pt-6" data-results>
      <div className="flex flex-col gap-1 pb-2">
        <h1 id="results" className="font-serif text-headline-m lg:text-headline-l">
          {t("searchResultsFor", { v: wanted.q })}
        </h1>
        {found.results.length > 0 && <h2 className="font-sans text-caption text-text-secondary">{count}</h2>}
      </div>
      {found.results.length === 0 ? (
        <Designed
          kind="empty"
          title={t("searchNoneTitle")}
          body={t("searchNoneBody")}
          level={2}
          action={
            <a href={base} className={BUTTON}>
              {t("navExplore")}
            </a>
          }
        />
      ) : (
        <>
          <ul className="grid grid-cols-1 gap-x-12 max-lg:divide-y max-lg:divide-border lg:grid-cols-2 lg:gap-y-2">
            {found.results.map((hit) => (
              <li key={hit.card.id} className="py-4">
                <RowCard card={hit.card as CardData} env={env} />
                <Snippet hit={hit} />
              </li>
            ))}
          </ul>
          <More
            href={found.next_cursor ? addressOf(base, wanted, { cursor: found.next_cursor }) : undefined}
            t={t}
            label={t("searchMore")}
          />
        </>
      )}
    </section>
  );
}

/** The field where the page has it, the same on the page and in its skeleton. */
export const SearchTop = ({ base, wanted, t }: { base: string; wanted: Wanted; t: T }) => (
  <div className="pt-4 lg:pt-8">
    <SearchForm base={base} wanted={wanted} t={t} />
  </div>
);

/** While results come: their heading, their count and their rows, where they will stand. */
export function ResultsBones({ env }: { env: NewsEnv }) {
  return (
    <section className="pt-4 lg:pt-6" data-results>
      <div className="flex flex-col gap-1 pb-2">
        <p className="font-serif text-headline-m lg:text-headline-l">
          <Bone className="w-2/3" />
        </p>
        <p className="text-caption">
          <Bone className="w-32" />
        </p>
      </div>
      <ul className="grid grid-cols-1 gap-x-12 max-lg:divide-y max-lg:divide-border lg:grid-cols-2 lg:gap-y-2">
        {none(8).map((card, i) => (
          // biome-ignore lint/suspicious/noArrayIndexKey: bones never move
          <li key={i} className="py-4">
            <RowCard card={card} env={env} />
          </li>
        ))}
      </ul>
    </section>
  );
}
