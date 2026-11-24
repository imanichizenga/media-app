import { ArticleBody, type ContentContext } from "@news/ui/content";
import { Picture } from "@news/ui/media";
import {
  ACTIONS,
  type Action,
  ActionBar,
  ago,
  BreakingBanner,
  type CardData,
  compact,
  Designed,
  exact,
  LeadCard,
  LivePill,
  LiveRail,
  RowCard,
  SectionHeading,
  ShortCard,
  StoryCard,
  TextCard,
  VideoCard,
} from "@news/ui/news";
import { Bone, Button, cx } from "@news/ui/primitives";
import {
  ALargeSmall,
  ArrowRight,
  Bell,
  Check,
  ChevronDown,
  Cpu,
  Earth,
  Eye,
  Globe,
  GraduationCap,
  Heart,
  HeartPulse,
  Landmark,
  Leaf,
  type LucideIcon,
  MessageSquareQuote,
  Music,
  Newspaper,
  Pin,
  Play,
  Search,
  SendHorizontal,
  TrendingUp,
  Trophy,
  Volume2,
  X,
} from "lucide-react";
import type { ReactNode } from "react";
import { AppFrame, type Data, Frame, type Page, Tabs, Wide } from "./frame";

const none = (n: number): undefined[] => Array.from({ length: n }, () => undefined);
const photo = (p: Page, n: number): CardData => p.d.latest.filter((c: CardData) => c.image)[n];
const context = (p: Page, a: Data): ContentContext => ({
  assets: a.assets,
  links: a.links,
  mediaBase: p.env.mediaBase,
  labels: {
    play: p.t.play,
    playError: p.t.errorTitle,
    sensitive: p.t.sensitive,
    readAlso: p.t.readAlso,
    openPost: p.t.watch,
    unsupported: p.t.errorTitle,
    pinned: p.t.pinned,
    gallery: p.t.gallery,
  },
  interactive: false,
  formatTime: (iso) => ago(iso, p.env),
});
const policy = (p: Page, liked = false): Action[] => [
  { key: "like", label: p.t.actions.like, icon: ACTIONS.like, count: liked ? 1285 : 1284, active: liked },
  { key: "comment", label: p.t.actions.comment, icon: ACTIONS.comment, count: 48 },
  { key: "bookmark", label: p.t.actions.bookmark, icon: ACTIONS.bookmark },
  { key: "share", label: p.t.actions.share, icon: ACTIONS.share },
];

// ---- home ----
const FeedTabs = ({ p, className }: { p: Page; className?: string }) => (
  <div role="tablist" className={cx("flex rounded-full bg-surface-sunken p-1", className)}>
    {[p.t.forYou, p.t.latest].map((name, i) => (
      <button
        key={name}
        type="button"
        role="tab"
        aria-selected={i === 0}
        className={cx(
          "tap flex-1 rounded-full text-label",
          i === 0 ? "bg-surface-raised shadow-sm" : "text-text-secondary",
        )}
      >
        {name}
      </button>
    ))}
  </div>
);
function Home({ p, loading = false }: { p: Page; loading?: boolean }) {
  const { d, t, env } = p;
  const h = d.home;
  const lead: (CardData | undefined)[] = loading ? none(5) : h.lead;
  const latest: (CardData | undefined)[] = loading ? none(8) : h.latest;
  const videos: (CardData | undefined)[] = loading ? none(4) : h.videos;
  const shorts: (CardData | undefined)[] = loading ? none(6) : h.shorts;
  const sections: Data[] = loading ? none(2) : h.sections;
  return (
    <Frame p={p} tab="home">
      {/* Part of the frame: known before the page is, so it never pushes the page down. */}
      <BreakingBanner card={p.breaking} env={env} />
      <Wide className="flex flex-col gap-4 pt-4 lg:gap-6 lg:pt-6">
        <div className="flex flex-col gap-4">
          <LiveRail cards={loading ? undefined : h.live} env={env} title={t.liveNow} />
          {/* The app. On the website it arrives with recommendations (M8). */}
          <FeedTabs p={p} className="lg:hidden" />
        </div>
        <div className="grid gap-x-8 gap-y-8 lg:grid-cols-12">
          <LeadCard card={lead[0]} env={env} priority className="lg:col-span-6" />
          <div className="flex flex-col gap-6 lg:col-span-3">
            <div className="hidden flex-col gap-6 lg:flex">
              {lead.slice(1, 3).map((card, i) => (
                <StoryCard key={card?.id ?? i} card={card} env={env} />
              ))}
            </div>
            <ul className="divide-y divide-border border-border border-t lg:hidden">
              {lead.slice(1, 5).map((card, i) => (
                <li key={card?.id ?? i} className="py-4">
                  <RowCard card={card} env={env} />
                </li>
              ))}
            </ul>
          </div>
          <section aria-label={t.latest} className="lg:col-span-3 lg:border-border lg:border-l lg:pl-8">
            <SectionHeading title={t.latest} href="#" env={env} />
            <ul className="divide-y divide-border">
              {latest.slice(0, 7).map((card, i) => (
                <li key={card?.id ?? i} className="py-3 first:pt-0">
                  <TextCard card={card} env={env} />
                </li>
              ))}
            </ul>
          </section>
        </div>
      </Wide>
      <section aria-label={t.videos} className="mt-12 bg-surface-sunken py-8">
        <Wide>
          <SectionHeading title={t.videos} href="#" env={env} />
          <ul className="-mx-4 flex gap-4 overflow-x-auto px-4 scrollbar-none lg:grid lg:grid-cols-4 lg:gap-6">
            {videos.slice(0, 4).map((card, i) => (
              <li key={card?.id ?? i} className="w-72 shrink-0 lg:w-auto">
                <VideoCard card={card} env={env} />
              </li>
            ))}
          </ul>
          <h3 className="pt-8 pb-4 font-serif text-headline-s">{t.shorts}</h3>
          <ul className="-mx-4 flex gap-3 overflow-x-auto px-4 scrollbar-none lg:grid lg:grid-cols-6 lg:gap-6">
            {shorts.slice(0, 6).map((card, i) => (
              <li key={card?.id ?? i} className="w-36 shrink-0 lg:w-auto">
                <ShortCard card={card} env={env} />
              </li>
            ))}
          </ul>
        </Wide>
      </section>
      <Wide className="flex flex-col gap-12 pt-12">
        {sections.slice(0, 4).map((section, i) => {
          const cards: (CardData | undefined)[] = section?.results ?? none(5);
          return (
            <section key={section?.category.id ?? i}>
              <SectionHeading
                title={section?.category.name}
                href={section ? "category.html" : undefined}
                env={env}
              />
              {i % 2 === 0 ? (
                <div className="grid gap-x-8 gap-y-6 lg:grid-cols-12">
                  <StoryCard card={cards[0]} env={env} className="lg:col-span-5" />
                  <ul className="divide-y divide-border lg:col-span-7">
                    {cards.slice(1, 4).map((card, k) => (
                      <li key={card?.id ?? k} className="py-4 first:pt-0">
                        <RowCard card={card} env={env} />
                      </li>
                    ))}
                  </ul>
                </div>
              ) : (
                <ul className="grid grid-cols-2 gap-x-4 gap-y-8 lg:grid-cols-4 lg:gap-x-8">
                  {cards.slice(0, 4).map((card, k) => (
                    <li key={card?.id ?? k}>
                      <StoryCard card={card} env={env} />
                    </li>
                  ))}
                </ul>
              )}
            </section>
          );
        })}
      </Wide>
    </Frame>
  );
}

// ---- article ----
function ArticleHead({ p, loading = false }: { p: Page; loading?: boolean }) {
  const { d, t, env } = p;
  const a = d.article;
  return (
    <>
      <header className="flex flex-col gap-4">
        <p className="font-semibold text-label text-text-primary">
          {loading ? <Bone className="w-24" /> : <a href="category.html">{a.category.name}</a>}
        </p>
        <h1 className="font-serif text-headline-l lg:text-display">
          {loading ? ["w-full", "w-2/3"].map((w) => <Bone key={w} className={w} />) : a.headline}
        </h1>
        <p className="text-body-l text-text-secondary lg:text-headline-s lg:font-normal!">
          {loading ? ["w-full", "w-1/2"].map((w) => <Bone key={w} className={w} />) : a.standfirst}
        </p>
        <div className="flex items-center gap-3 border-border border-y py-3">
          <span className="size-12 shrink-0 overflow-hidden rounded-full bg-surface-sunken">
            {loading ? (
              <span aria-hidden className="bone block! size-full" />
            ) : (
              a.authors[0].avatar && (
                <Picture
                  image={a.authors[0].avatar}
                  mediaBase={env.mediaBase}
                  alt=""
                  sizes="48px"
                  className="size-full object-cover"
                />
              )
            )}
          </span>
          <div className="min-w-0 flex-1">
            <p className="text-label">{loading ? <Bone className="w-32" /> : a.authors[0].name}</p>
            <p className="text-caption text-text-secondary">
              {loading ? (
                <Bone className="w-48" />
              ) : (
                `${t.published} ${ago(a.published_at, env)} · ${t.minutes(Math.max(3, a.reading_minutes))}`
              )}
            </p>
          </div>
          {loading ? (
            <span aria-hidden className="tap bone w-20" />
          ) : (
            <Button variant="secondary">{t.follow}</Button>
          )}
          <button
            type="button"
            aria-label={t.textSize}
            className="tap hidden w-11 place-items-center rounded-sm hover:bg-surface-sunken sm:grid"
          >
            <ALargeSmall aria-hidden size={22} />
          </button>
        </div>
      </header>
      <figure className="-mx-4 sm:mx-0">
        <div className="aspect-3/2 overflow-hidden bg-surface-sunken sm:rounded-md">
          {loading ? (
            <span aria-hidden className="bone block! size-full rounded-none!" />
          ) : (
            <Picture
              image={a.image}
              mediaBase={env.mediaBase}
              sizes="(min-width: 1024px) 704px, 100vw"
              priority
              className="size-full object-cover"
            />
          )}
        </div>
        <figcaption className="px-4 pt-2 text-caption text-text-tertiary sm:px-0">
          {loading ? <Bone className="w-40" /> : a.image.credit}
        </figcaption>
      </figure>
    </>
  );
}
function Article({
  p,
  loading = false,
  sheet,
  liked,
}: {
  p: Page;
  loading?: boolean;
  sheet?: ReactNode;
  liked?: boolean;
}) {
  const { d, t, env } = p;
  const a = d.article;
  const related: (CardData | undefined)[] = loading ? none(4) : d.related;
  return (
    <>
      <Frame
        p={p}
        tab="home"
        section={a.category.name}
        bottom={<ActionBar actions={policy(p, liked)} locale={p.locale} className="h-14 items-center" />}
      >
        <div className="mx-auto grid max-w-7xl gap-x-8 px-4 pt-6 lg:grid-cols-[5rem_minmax(0,44rem)_minmax(0,1fr)] lg:pt-10">
          <aside className="hidden lg:block">
            <div className="sticky top-8">
              <ActionBar actions={policy(p, liked)} locale={p.locale} vertical />
            </div>
          </aside>
          <article className="flex flex-col gap-6">
            <ArticleHead p={p} loading={loading} />
            {loading ? (
              <ArticleBody.Skeleton />
            ) : (
              <>
                <p className="rounded-md border-warning border-l-4 bg-warning-soft px-4 py-3 text-warning">
                  <strong className="font-semibold">{t.correction}.</strong> {t.correctionText}
                </p>
                <ArticleBody document={a.body} context={context(p, a)} />
                <ul className="flex flex-wrap gap-2 border-border border-t pt-6">
                  {a.tags.map((tag: { slug: string; name: string }) => (
                    <li key={tag.slug}>
                      <a
                        href="category.html"
                        className="tap inline-flex items-center rounded-full border border-border px-4 text-label hover:bg-surface-sunken"
                      >
                        {tag.name}
                      </a>
                    </li>
                  ))}
                </ul>
              </>
            )}
            <section className="pt-6 lg:hidden">
              <SectionHeading title={t.readAlso} env={env} />
              <ul className="divide-y divide-border">
                {related.slice(0, 4).map((card, i) => (
                  <li key={card?.id ?? i} className="py-4 first:pt-0">
                    <RowCard card={card} env={env} />
                  </li>
                ))}
              </ul>
            </section>
          </article>
          <aside className="hidden pl-8 lg:block">
            <div className="sticky top-8">
              <SectionHeading title={t.readAlso} env={env} />
              <ul className="flex flex-col gap-6">
                {related.slice(0, 4).map((card, i) => (
                  <li key={card?.id ?? i}>
                    <RowCard card={card} env={env} />
                  </li>
                ))}
              </ul>
            </div>
          </aside>
        </div>
      </Frame>
      {sheet}
    </>
  );
}

// ---- the app in wide windows (D7) ----
function HomeWide({ p }: { p: Page }) {
  const { d, t, env } = p;
  const h = d.home;
  const feed: CardData[] = [...h.lead.slice(1, 5), ...h.latest.slice(0, 10)];
  return (
    <AppFrame p={p} tab="home">
      <BreakingBanner card={p.breaking} env={env} />
      <div className="flex flex-col gap-6 px-6 pt-4">
        <LiveRail cards={h.live} env={env} title={t.liveNow} />
        <FeedTabs p={p} className="max-w-md" />
        <div className="grid gap-x-8 gap-y-8 expanded:grid-cols-[2fr_1fr]">
          <LeadCard card={h.lead[0]} env={env} priority />
          <section aria-label={t.latest} className="max-expanded:hidden">
            <SectionHeading title={t.latest} env={env} />
            <ul className="divide-y divide-border">
              {h.latest.slice(10, 16).map((card: CardData) => (
                <li key={card.id} className="py-3 first:pt-0">
                  <TextCard card={card} env={env} />
                </li>
              ))}
            </ul>
          </section>
        </div>
        <ul className="grid grid-cols-2 gap-x-8 gap-y-8 border-border border-t pt-6 expanded:grid-cols-3">
          {feed.map((card) => (
            <li key={card.id}>
              {card.duration_ms ? <VideoCard card={card} env={env} /> : <StoryCard card={card} env={env} />}
            </li>
          ))}
        </ul>
      </div>
    </AppFrame>
  );
}
function ArticleWide({ p }: { p: Page }) {
  const { d, t, env } = p;
  const a = d.article;
  return (
    <AppFrame
      p={p}
      tab="home"
      bottom={
        <ActionBar
          actions={policy(p)}
          locale={p.locale}
          className="mx-auto h-14 max-w-[42.5rem] items-center"
        />
      }
    >
      <div className="mx-auto grid max-w-6xl justify-center gap-x-10 px-6 pt-8 expanded:grid-cols-[minmax(0,42.5rem)_15rem]">
        <article className="mx-auto flex w-full max-w-[42.5rem] flex-col gap-6">
          <ArticleHead p={p} />
          <ArticleBody document={a.body} context={context(p, a)} />
          <section className="pt-6 expanded:hidden">
            <SectionHeading title={t.readAlso} env={env} />
            <ul className="grid grid-cols-2 gap-8">
              {d.related.slice(0, 4).map((card: CardData) => (
                <li key={card.id}>
                  <StoryCard card={card} env={env} />
                </li>
              ))}
            </ul>
          </section>
        </article>
        <aside className="max-expanded:hidden">
          <div className="sticky top-20">
            <SectionHeading title={t.readAlso} env={env} />
            <ul className="flex flex-col gap-6">
              {d.related.slice(0, 3).map((card: CardData) => (
                <li key={card.id}>
                  <StoryCard card={card} env={env} />
                </li>
              ))}
            </ul>
          </div>
        </aside>
      </div>
    </AppFrame>
  );
}

// ---- sheets ----
function Sheet({
  title,
  p,
  children,
  side = false,
  label,
}: {
  title: ReactNode;
  p: Page;
  children: ReactNode;
  side?: boolean;
  label: string;
}) {
  return (
    <div className="fixed inset-0 z-40 flex items-end bg-black/50 lg:items-center lg:justify-center">
      <div
        role="dialog"
        aria-label={label}
        className={cx(
          "flex w-full flex-col rounded-t-xl bg-surface-raised shadow-2xl",
          side ? "h-[86dvh] lg:ml-auto lg:h-dvh lg:w-[28rem] lg:rounded-none" : "lg:w-[27rem] lg:rounded-xl",
        )}
      >
        <span aria-hidden className="mx-auto mt-2 h-1 w-10 rounded-full bg-border-strong lg:hidden" />
        <div className="flex items-center justify-between gap-2 py-2 pr-2 pl-5">
          <h2 className="font-serif text-headline-s">{title}</h2>
          <button
            type="button"
            aria-label={p.t.close}
            className="tap grid w-11 place-items-center rounded-full hover:bg-surface-sunken"
          >
            <X aria-hidden size={20} />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
const GOOGLE = [
  [
    "#4285F4",
    "M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5a5.5 5.5 0 0 1-2.4 3.6v3h3.9c2.2-2.1 3.5-5.1 3.5-8.8Z",
  ],
  [
    "#34A853",
    "M12 24c3.2 0 6-1.1 8-2.9l-3.9-3c-1.1.7-2.5 1.2-4.1 1.2-3.1 0-5.8-2.1-6.7-5H1.2v3.1A12 12 0 0 0 12 24Z",
  ],
  ["#FBBC05", "M5.3 14.3a7.200 7.200 0 0 1 0-4.600V6.600H1.200a12 12 0 0 0 0 10.800l4.100-3.100Z"],
  [
    "#EA4335",
    "M12 4.800c1.800 0 3.300.6 4.600 1.800l3.400-3.400A12 12 0 0 0 1.200 6.600l4.100 3.100c.9-2.900 3.600-4.900 6.700-4.900Z",
  ],
] as const;
const APPLE =
  "M17.1 12.700c0-2.400 2-3.600 2.100-3.600-1.100-1.700-2.900-1.900-3.500-1.900-1.500-.2-2.900.9-3.600.9-.8 0-1.900-.9-3.200-.8-1.600 0-3.100.9-4 2.400-1.700 2.900-.4 7.300 1.200 9.700.8 1.200 1.800 2.500 3.100 2.400 1.200 0 1.700-.8 3.200-.8s1.900.8 3.200.8c1.300 0 2.200-1.200 3-2.300.9-1.400 1.300-2.700 1.300-2.700s-2.800-1.100-2.800-4.100ZM14.700 5.600c.7-.8 1.100-1.900 1-3-.9 0-2.100.6-2.800 1.400-.6.7-1.200 1.800-1 2.900 1 .1 2.100-.5 2.800-1.300Z";
function AuthSheet({ p, code = false }: { p: Page; code?: boolean }) {
  const { t, env } = p;
  const a = p.d.article;
  return (
    <Sheet p={p} title={code ? t.codeTitle : t.signInTo} label={t.signInTo}>
      <div className="flex flex-col gap-4 px-5 pb-8">
        {code ? (
          <>
            <p className="text-text-secondary">{t.codeSent}</p>
            <fieldset aria-label={t.codeLabel} className="flex justify-between gap-2">
              {["4", "0", "7", "", "", ""].map((digit, i) => (
                <span
                  // biome-ignore lint/suspicious/noArrayIndexKey: six fixed boxes
                  key={i}
                  className={cx(
                    "grid h-14 flex-1 place-items-center rounded-md border text-headline-m tabular-nums",
                    i === 3 ? "border-2 border-focus" : "border-border-strong",
                  )}
                >
                  {digit || (i === 3 && <span className="h-6 w-0.5 bg-text-primary" />)}
                </span>
              ))}
            </fieldset>
            <div className="flex items-center justify-between text-label">
              <button type="button" className="tap text-text-primary underline underline-offset-4">
                {t.changeNumber}
              </button>
              <span className="text-text-secondary tabular-nums">{t.resend}</span>
            </div>
          </>
        ) : (
          <>
            <div className="flex items-center gap-3 rounded-md bg-surface-sunken p-3">
              <span className="relative size-14 shrink-0 overflow-hidden rounded-sm">
                <Picture
                  image={a.image}
                  mediaBase={env.mediaBase}
                  alt=""
                  sizes="56px"
                  className="size-full object-cover"
                />
              </span>
              <p className="min-w-0 flex-1 text-caption text-text-secondary">{t.signInWhy}</p>
              <Heart aria-hidden size={22} fill="currentColor" className="shrink-0 text-liked" />
            </div>
            <label className="flex flex-col gap-1 text-label">
              {t.phone}
              <span className="flex overflow-hidden rounded-sm border border-border-strong focus-within:border-focus">
                <span className="tap inline-flex items-center gap-1 border-border border-r px-3">
                  +255 <ChevronDown aria-hidden size={16} />
                </span>
                <input
                  type="tel"
                  inputMode="tel"
                  autoComplete="tel-national"
                  placeholder="7XX XXX XXX"
                  className="min-w-0 flex-1 bg-transparent px-3 text-body-m outline-none placeholder:text-text-tertiary"
                />
              </span>
            </label>
            <Button className="w-full">{t.continue}</Button>
            <p className="flex items-center gap-3 text-caption text-text-secondary before:h-px before:flex-1 before:bg-border after:h-px after:flex-1 after:bg-border">
              {t.or}
            </p>
            <Button variant="secondary" className="w-full">
              <svg aria-hidden="true" viewBox="0 0 24 24" className="size-5">
                {GOOGLE.map(([fill, path]) => (
                  <path key={fill} fill={fill} d={path} />
                ))}
              </svg>
              {t.google}
            </Button>
            <Button variant="secondary" className="w-full">
              <svg aria-hidden="true" viewBox="0 0 24 24" className="size-5">
                <path fill="currentColor" d={APPLE} />
              </svg>
              {t.apple}
            </Button>
            <p className="text-center text-caption text-text-secondary">{t.legal}</p>
          </>
        )}
      </div>
    </Sheet>
  );
}

function Comment({
  p,
  i,
  name,
  body,
  likes,
  replies = 0,
  mark,
  pinned,
  nested,
}: {
  p: Page;
  i: number;
  name: string;
  body: string;
  likes: number;
  replies?: number;
  mark?: string;
  pinned?: boolean;
  nested?: boolean;
}) {
  return (
    <li className={cx("flex gap-3", nested && "pl-12")}>
      <span
        aria-hidden
        className={cx(
          "grid shrink-0 place-items-center rounded-full bg-surface-sunken text-text-secondary",
          nested ? "size-8 text-caption" : "size-9 text-label",
        )}
      >
        {name.slice(0, 1)}
      </span>
      <div className="min-w-0 flex-1">
        {pinned && (
          <p className="flex items-center gap-1 text-caption text-text-secondary">
            <Pin aria-hidden size={12} /> {p.t.pinned}
          </p>
        )}
        <p className="flex flex-wrap items-center gap-x-2">
          <span className="text-label">{name}</span>
          {mark && (
            <span className="rounded-sm bg-surface-sunken px-1.5 text-caption text-text-primary">{mark}</span>
          )}
          <span className="text-caption text-text-secondary">
            {ago(new Date(p.env.now - (i + 1) * 7 * 60_000).toISOString(), p.env)}
          </span>
        </p>
        <p className="break-words">{body}</p>
        <button type="button" className="tap -ml-2 px-2 text-caption text-text-secondary">
          {p.t.reply}
        </button>
        {replies > 0 && (
          <button type="button" className="tap flex items-center gap-3 text-caption text-text-secondary">
            <span aria-hidden className="h-px w-6 bg-border-strong" /> {p.t.replies(replies)}
          </button>
        )}
      </div>
      <button
        type="button"
        aria-label={`${p.t.actions.like}, ${exact(likes, p.locale)}`}
        className="tap flex w-11 flex-col items-center justify-center text-caption text-text-secondary"
      >
        <Heart
          aria-hidden
          size={18}
          className={i === 0 ? "text-liked" : ""}
          fill={i === 0 ? "currentColor" : "none"}
        />
        <span className="tabular-nums">{compact(likes, p.locale)}</span>
      </button>
    </li>
  );
}
const SAID = {
  sw: [
    "Hongera kwa timu nzima. Tunahitaji hadithi kama hizi zaidi.",
    "Asante kwa kusoma! Kesho tutachapisha mahojiano kamili na mkurugenzi.",
    "Je, filamu itaonyeshwa pia mikoani au Dar pekee?",
    "Mikoani pia. Ratiba inaanza Mbeya wiki ijayo.",
    "Nimeitazama mara mbili. Sauti na rangi zake ni za kiwango cha juu sana.",
    "Ningependa kujua zaidi kuhusu wanafunzi walioshiriki.",
  ],
  en: [
    "Well done to the whole team. We need more stories like this.",
    "Thank you for reading! Tomorrow we publish the full interview with the director.",
    "Will the film be shown in the regions too, or only in Dar?",
    "In the regions too. It starts in Mbeya next week.",
    "I have seen it twice. The sound and the colours are of a very high standard.",
    "I would like to know more about the students who took part.",
  ],
};
function CommentsSheet({ p }: { p: Page }) {
  const { t } = p;
  const said = SAID[p.locale];
  const at = (i: number) => said[i] ?? "";
  return (
    <Sheet p={p} side label={t.comments} title={`${t.comments} · 48`}>
      <div className="flex gap-2 border-border border-b px-5 pb-3">
        {[t.top, t.newest].map((name, i) => (
          <button
            key={name}
            type="button"
            aria-pressed={i === 0}
            className={cx(
              "tap rounded-full px-4 text-label",
              i === 0 ? "bg-text-primary text-bg" : "border border-border text-text-secondary",
            )}
          >
            {name}
          </button>
        ))}
      </div>
      <ul className="flex flex-1 flex-col gap-3 overflow-y-auto py-4 pr-2 pl-5">
        <Comment p={p} i={0} name="Salma Mrisho" body={at(0)} likes={132} />
        <Comment
          p={p}
          i={1}
          name={p.d.article.authors[0].name}
          body={at(1)}
          likes={96}
          mark={t.author}
          pinned
        />
        <Comment p={p} i={2} name="Juma Kitwana" body={at(2)} likes={41} />
        <Comment p={p} i={3} name="Rehema Chuwa" body={at(3)} likes={18} nested />
        <Comment p={p} i={4} name="Hamisi Mtoro" body={at(4)} likes={27} replies={3} />
        <Comment p={p} i={5} name="Neema" body={at(5)} likes={9} />
      </ul>
      <div className="flex items-center gap-2 border-border border-t p-3 pb-[max(0.75rem,env(safe-area-inset-bottom))]">
        <span
          aria-hidden
          className="grid size-9 place-items-center rounded-full bg-surface-sunken text-label text-text-secondary"
        >
          A
        </span>
        <input
          aria-label={t.writeComment}
          placeholder={t.writeComment}
          className="tap min-w-0 flex-1 rounded-full border border-border-strong bg-transparent px-4"
        />
        <button
          type="button"
          aria-label={t.send}
          className="tap grid w-11 place-items-center rounded-full bg-brand text-on-brand"
        >
          <SendHorizontal aria-hidden size={18} />
        </button>
      </div>
    </Sheet>
  );
}

// ---- video ----
function VideoTabs({ p, at, onDark }: { p: Page; at: 0 | 1; onDark?: boolean }) {
  return (
    <div role="tablist" className="flex justify-center gap-2">
      {[p.t.shortsTab, p.t.longTab].map((name, i) => (
        <button
          type="button"
          key={name}
          role="tab"
          aria-selected={i === at}
          className={cx(
            "tap inline-flex items-center border-b-2 px-4 text-label",
            i === at
              ? onDark
                ? "border-white text-white"
                : "border-brand-text text-text-primary"
              : cx("border-transparent", onDark ? "text-white/75" : "text-text-secondary"),
          )}
        >
          {name}
        </button>
      ))}
    </div>
  );
}
function Shorts({ p, loading = false }: { p: Page; loading?: boolean }) {
  const { d, t, env } = p;
  const card: CardData = d.home.shorts[0];
  const actions = policy(p, true).slice(0, 4);
  return (
    <div className="flex min-h-dvh flex-col bg-black text-white lg:items-center">
      <div className="relative flex-1 lg:my-6 lg:aspect-9/16 lg:max-h-[calc(100dvh-3rem)] lg:overflow-hidden lg:rounded-xl">
        {loading ? (
          <span aria-hidden className="absolute inset-0 animate-pulse bg-white/10" />
        ) : (
          card.video && (
            <img
              src={`${env.mediaBase}/${card.video.poster}`}
              alt=""
              className="absolute inset-0 size-full object-cover"
            />
          )
        )}
        <div className="absolute inset-x-0 top-0 bg-linear-to-b from-black/70 to-transparent pb-10">
          <VideoTabs p={p} at={0} onDark />
        </div>
        <button
          type="button"
          aria-label={t.mute}
          className="tap absolute top-14 right-3 grid w-11 place-items-center rounded-full bg-black/50"
        >
          <Volume2 aria-hidden size={20} />
        </button>
        <div className="absolute inset-x-0 bottom-0 flex items-end gap-4 bg-linear-to-t from-black/90 via-black/50 to-transparent p-4 pt-48">
          <div className="min-w-0 flex-1">
            <p className="flex items-center gap-2 text-caption">
              {loading ? (
                <span className="inline-block h-4 w-24 rounded-sm bg-white/20" />
              ) : (
                <>
                  <span className="font-semibold">{card.category.name}</span> · {ago(card.published_at, env)}
                </>
              )}
            </p>
            <h1 className="py-1 font-serif text-headline-s">
              {loading ? <span className="inline-block h-6 w-full rounded-sm bg-white/20" /> : card.headline}
            </h1>
            <a href="article.html" className="tap inline-flex items-center gap-1 text-label">
              {t.watch} <ArrowRight aria-hidden size={16} />
            </a>
          </div>
          <ul className="flex flex-col gap-1 drop-shadow-[0_1px_3px_rgb(0_0_0/0.85)]">
            {actions.map(({ key, label, icon: Icon, count, active }) => (
              <li key={key}>
                <button
                  type="button"
                  aria-label={count === undefined ? label : `${label}, ${exact(count, p.locale)}`}
                  aria-pressed={active}
                  className={cx(
                    "tap flex w-14 flex-col items-center justify-center py-1 text-caption",
                    active && "[&>svg]:text-liked-on-dark",
                  )}
                >
                  <Icon aria-hidden size={26} fill={active ? "currentColor" : "none"} />
                  {count !== undefined && <span className="tabular-nums">{compact(count, p.locale)}</span>}
                </button>
              </li>
            ))}
          </ul>
        </div>
        <span aria-hidden className="absolute inset-x-0 bottom-0 h-0.5 bg-white/25">
          <span className="block h-full w-2/5 bg-white" />
        </span>
      </div>
      <div className="border-white/15 border-t lg:hidden">
        <Tabs t={t} tab="video" onDark />
      </div>
    </div>
  );
}
function Video({ p, loading = false }: { p: Page; loading?: boolean }) {
  const { d, env } = p;
  const cards: (CardData | undefined)[] = loading ? none(8) : d.videos;
  const lead = cards[0];
  return (
    <Frame p={p} tab="video" bare>
      <Wide className="pt-2">
        <VideoTabs p={p} at={1} />
        <div className="grid gap-x-8 gap-y-8 pt-4 lg:grid-cols-12">
          <LeadCard card={lead} env={env} priority className="lg:col-span-8" />
          <ul className="flex flex-col gap-6 lg:col-span-4">
            {cards.slice(1, 4).map((card, i) => (
              <li key={card?.id ?? i}>
                <VideoCard card={card} env={env} />
              </li>
            ))}
          </ul>
        </div>
        <ul className="grid gap-x-6 gap-y-8 pt-10 sm:grid-cols-2 lg:grid-cols-4">
          {cards.slice(4, 12).map((card, i) => (
            <li key={card?.id ?? i}>
              <VideoCard card={card} env={env} />
            </li>
          ))}
        </ul>
      </Wide>
    </Frame>
  );
}

// ---- live ----
function Live({ p, loading = false }: { p: Page; loading?: boolean }) {
  const { d, t, env } = p;
  const a = d.live;
  const updates: Data[] = loading ? none(5) : a.body.blocks.slice(0, 8);
  return (
    <Frame p={p} tab="home" bare>
      <div className="mx-auto grid max-w-7xl gap-8 lg:grid-cols-12 lg:px-4 lg:pt-8">
        <div className="lg:col-span-8">
          <div className="relative aspect-video overflow-hidden bg-black lg:rounded-md">
            {loading ? (
              <span aria-hidden className="bone block! size-full rounded-none!" />
            ) : (
              <>
                <Picture
                  image={a.image}
                  mediaBase={env.mediaBase}
                  alt=""
                  sizes="(min-width: 1024px) 800px, 100vw"
                  priority
                  className="size-full object-cover"
                />
                <div className="absolute inset-x-0 top-0 flex items-center gap-2 bg-linear-to-b from-black/70 to-transparent p-3 text-white">
                  <LivePill label={t.live} />
                  <span className="inline-flex items-center gap-1 text-caption tabular-nums">
                    <Eye aria-hidden size={16} /> {t.viewers}
                  </span>
                </div>
                <button
                  type="button"
                  aria-label={t.play}
                  className="absolute inset-0 m-auto grid size-16 place-items-center rounded-full bg-black/60 text-white"
                >
                  <Play aria-hidden size={28} fill="currentColor" />
                </button>
              </>
            )}
          </div>
          <div className="flex flex-col gap-3 px-4 pt-5 lg:px-0">
            <h1 className="font-serif text-headline-l">
              {loading ? ["w-full", "w-1/2"].map((w) => <Bone key={w} className={w} />) : a.headline}
            </h1>
            <p className="text-text-secondary">{loading ? <Bone className="w-full" /> : a.standfirst}</p>
          </div>
          <div role="tablist" className="mt-4 flex border-border border-b px-4 lg:px-0">
            {[t.updates, t.chat].map((name, i) => (
              <button
                type="button"
                key={name}
                role="tab"
                aria-selected={i === 0}
                className={cx(
                  "tap inline-flex items-center border-b-2 px-4 text-label",
                  i === 0
                    ? "border-brand-text text-text-primary"
                    : "border-transparent text-text-secondary lg:hidden",
                )}
              >
                {name}
              </button>
            ))}
          </div>
          <div className="px-4 pt-4 lg:px-0">
            {!loading && (
              <div className="sticky top-16 z-10 flex justify-center pb-4">
                <Button className="rounded-full! shadow-lg">{t.newUpdates(3)}</Button>
              </div>
            )}
            <ol className="flex flex-col border-border border-l-2">
              {updates.map((block, i) => (
                <li key={block?.id ?? i} className="relative pb-8 pl-6">
                  <span
                    aria-hidden
                    className={cx(
                      "absolute top-1.5 -left-[7px] size-3 rounded-full",
                      i === 0 && block ? "bg-text-primary" : "bg-border-strong",
                    )}
                  />
                  <p className="text-caption text-text-secondary">
                    {block ? (
                      <time dateTime={block.time}>{ago(block.time, env)}</time>
                    ) : (
                      <Bone className="w-24" />
                    )}
                  </p>
                  <div className="pt-1">
                    {block ? (
                      <ArticleBody document={{ version: 1, blocks: block.blocks }} context={context(p, a)} />
                    ) : (
                      <p className="text-body-l">
                        <Bone className="w-full" />
                        <Bone className="w-2/3" />
                      </p>
                    )}
                  </div>
                </li>
              ))}
            </ol>
          </div>
        </div>
        <aside className="hidden lg:col-span-4 lg:block">
          <section
            aria-label={t.chat}
            className="sticky top-8 flex h-[36rem] flex-col rounded-md border border-border bg-surface"
          >
            <h2 className="border-border border-b px-4 py-3 text-title">{t.chat}</h2>
            <ul className="flex flex-1 flex-col justify-end gap-4 p-4">
              {t.chatLines.map(([name, line], i) => (
                <li key={line}>
                  <span className={cx("text-label", i === 2 && "underline decoration-2 underline-offset-4")}>
                    {name}
                  </span>{" "}
                  <span className="text-text-secondary">{line}</span>
                </li>
              ))}
            </ul>
            <div className="flex gap-2 border-border border-t p-3">
              <input
                aria-label={t.chatPlaceholder}
                placeholder={t.chatPlaceholder}
                className="tap min-w-0 flex-1 rounded-full border border-border-strong bg-transparent px-4"
              />
              <button
                type="button"
                aria-label={t.send}
                className="tap grid w-11 place-items-center rounded-full bg-brand text-on-brand"
              >
                <SendHorizontal aria-hidden size={18} />
              </button>
            </div>
          </section>
        </aside>
      </div>
    </Frame>
  );
}

// ---- category ----
const chip = (on: boolean) =>
  cx(
    "tap inline-flex items-center whitespace-nowrap rounded-full px-4 text-label",
    on ? "bg-text-primary text-bg" : "border border-border text-text-secondary hover:bg-surface-sunken",
  );
function Category({ p, loading = false }: { p: Page; loading?: boolean }) {
  const { d, t, env } = p;
  const c = d.category.category;
  const cards: (CardData | undefined)[] = loading ? none(12) : d.category.results;
  return (
    <Frame p={p} tab="home" section={c.name}>
      <Wide className="pt-6 lg:pt-10">
        <h1 className="font-serif text-headline-l lg:text-display">
          {loading ? <Bone className="w-40" /> : c.name}
        </h1>
        <p className="max-w-xl pt-2 text-text-secondary">
          {loading ? <Bone className="w-64" /> : c.description || t.welcomeBody}
        </p>
        <ul className="-mx-4 flex gap-2 overflow-x-auto px-4 py-5 scrollbar-none">
          {loading
            ? none(3).map((_, i) => (
                // biome-ignore lint/suspicious/noArrayIndexKey: placeholders have no identity
                <li key={i}>
                  <span aria-hidden className="tap bone w-20 rounded-full!" />
                </li>
              ))
            : [{ id: "all", name: t.all }, ...c.children].map((x: { id: string; name: string }, i) => (
                <li key={x.id}>
                  <a href="category.html" className={chip(i === 0)}>
                    {x.name}
                  </a>
                </li>
              ))}
        </ul>
        <div className="grid gap-x-8 gap-y-8 lg:grid-cols-12">
          <LeadCard card={cards[0]} env={env} priority className="lg:col-span-8" />
          <ul className="flex flex-col gap-6 max-lg:hidden lg:col-span-4">
            {cards.slice(1, 3).map((card, i) => (
              <li key={card?.id ?? i}>
                <StoryCard card={card} env={env} />
              </li>
            ))}
          </ul>
        </div>
        <ul className="mt-8 divide-y divide-border border-border border-t lg:grid lg:grid-cols-2 lg:gap-x-12 lg:divide-y-0">
          {cards.slice(1, 11).map((card, i) => (
            <li key={card?.id ?? i} className={cx("py-4 lg:border-border lg:border-b", i < 2 && "lg:hidden")}>
              <RowCard card={card} env={env} />
            </li>
          ))}
        </ul>
      </Wide>
    </Frame>
  );
}

// ---- search ----
const ICONS: Record<string, LucideIcon> = {
  newspaper: Newspaper,
  landmark: Landmark,
  "trending-up": TrendingUp,
  trophy: Trophy,
  "heart-pulse": HeartPulse,
  "graduation-cap": GraduationCap,
  cpu: Cpu,
  music: Music,
  leaf: Leaf,
  globe: Globe,
  earth: Earth,
  "message-square-quote": MessageSquareQuote,
};
type Topic = { id: string; name: string; icon: string };
const SearchField = ({ p, value = "" }: { p: Page; value?: string }) => (
  <div className="flex items-center gap-3 rounded-full border border-border-strong bg-surface px-4 focus-within:border-focus">
    <Search aria-hidden size={20} className="shrink-0 text-text-secondary" />
    <input
      type="text"
      aria-label={p.t.search}
      placeholder={p.t.searchPlaceholder}
      defaultValue={value}
      className="tap min-w-0 flex-1 bg-transparent outline-none placeholder:text-text-tertiary"
    />
    {value && (
      <button type="button" aria-label={p.t.clear} className="tap -mr-3 grid w-11 place-items-center">
        <X aria-hidden size={18} />
      </button>
    )}
  </div>
);
function SearchPage({ p, state }: { p: Page; state: "start" | "results" | "loading" | "nothing" }) {
  const { d, t, env } = p;
  const found: (CardData | undefined)[] = state === "loading" ? none(6) : d.latest.slice(4, 11);
  const people = [
    ...new Map(
      d.latest.flatMap((c: CardData) => c.authors).map((a: { name: string }) => [a.name, a]),
    ).values(),
  ].slice(0, 5) as { name: string }[];
  return (
    <Frame p={p} tab="explore" bare>
      <div className="mx-auto max-w-3xl px-4 pt-4 lg:pt-10">
        <SearchField p={p} value={state === "start" ? "" : t.query} />
        {state === "start" ? (
          <div className="flex flex-col gap-10 pt-8">
            <section>
              <h2 className="pb-3 font-serif text-headline-s">{t.trending}</h2>
              <ol className="divide-y divide-border">
                {t.trends.map((name, i) => (
                  <li key={name} className="tap flex items-center gap-4">
                    <span className="w-6 font-serif text-headline-s text-text-tertiary tabular-nums">
                      {i + 1}
                    </span>
                    <span className="flex-1 text-body-m">{name}</span>
                    <TrendingUp aria-hidden size={18} className="text-text-tertiary" />
                  </li>
                ))}
              </ol>
            </section>
            <section>
              <h2 className="pb-3 font-serif text-headline-s">{t.categories}</h2>
              <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3">
                {d.navigation.map((n: Topic) => {
                  const Icon = ICONS[n.icon] ?? Newspaper;
                  return (
                    <li key={n.id}>
                      <a
                        href="category.html"
                        className="flex h-16 items-center gap-3 rounded-md border border-border bg-surface px-4 text-label hover:border-border-strong"
                      >
                        <Icon aria-hidden size={20} className="shrink-0 text-text-secondary" /> {n.name}
                      </a>
                    </li>
                  );
                })}
              </ul>
            </section>
            <section>
              <h2 className="pb-3 font-serif text-headline-s">{t.journalists}</h2>
              <ul className="divide-y divide-border">
                {people.map((a, i) => (
                  <li key={a.name} className="flex items-center gap-3 py-3">
                    <span
                      aria-hidden
                      className="grid size-12 place-items-center rounded-full bg-surface-sunken text-text-secondary text-title"
                    >
                      {a.name.slice(0, 1)}
                    </span>
                    <span className="flex-1 text-label">{a.name}</span>
                    <Button variant={i === 1 ? "ghost" : "secondary"}>
                      {i === 1 ? t.following : t.follow}
                    </Button>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        ) : state === "nothing" ? (
          <Designed
            kind="empty"
            title={t.notFoundTitle}
            body={t.notFoundBody}
            action={<Button variant="secondary">{t.clear}</Button>}
          />
        ) : (
          <>
            <ul className="flex gap-2 overflow-x-auto py-4 scrollbar-none">
              {Object.values(t.filters).map((name) => (
                <li key={name}>
                  <button type="button" className={chip(false)}>
                    {name} <ChevronDown aria-hidden size={16} className="ml-1" />
                  </button>
                </li>
              ))}
            </ul>
            <p className="pb-2 text-caption text-text-secondary">
              {state === "loading" ? <Bone className="w-36" /> : t.results(128, t.query)}
            </p>
            <ul className="divide-y divide-border">
              {found.map((card, i) => (
                <li key={card?.id ?? i} className="py-4">
                  <RowCard card={card} env={env} />
                </li>
              ))}
            </ul>
          </>
        )}
      </div>
    </Frame>
  );
}

// ---- onboarding (app) ----
/** Over any picture: its own ground, the same place on every step. */
const Skip = ({ p }: { p: Page }) => (
  <button type="button" className="tap rounded-full bg-black/75 px-5 text-label text-white">
    {p.t.skip}
  </button>
);
function Step({ p, at, children, action }: { p: Page; at: number; children: ReactNode; action: ReactNode }) {
  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col px-6 pt-4 pb-8 lg:my-8 lg:min-h-[50rem] lg:rounded-xl lg:border lg:border-border lg:bg-surface">
      <div className="flex items-center justify-between">
        <ol aria-hidden className="flex gap-1.5">
          {[1, 2, 3].map((i) => (
            <li key={i} className={cx("h-1 w-8 rounded-full", i <= at ? "bg-text-primary" : "bg-border")} />
          ))}
        </ol>
        <Skip p={p} />
      </div>
      <div className="flex flex-1 flex-col pt-8">{children}</div>
      <div className="flex flex-col gap-2">{action}</div>
    </div>
  );
}
function Welcome({ p }: { p: Page }) {
  const { t, env } = p;
  return (
    <div className="relative mx-auto flex min-h-dvh max-w-md flex-col justify-end overflow-hidden bg-black text-white lg:my-8 lg:min-h-[50rem] lg:rounded-xl">
      <div
        aria-hidden
        className="absolute inset-0 grid rotate-[-6deg] scale-125 grid-cols-2 gap-3 opacity-90"
      >
        {[0, 3, 5, 8, 11, 13, 16, 18].map((n) => {
          const card = photo(p, n);
          return (
            card?.image && (
              <Picture
                key={card.id}
                image={card.image}
                mediaBase={env.mediaBase}
                alt=""
                sizes="240px"
                className="aspect-4/3 w-full rounded-md object-cover"
              />
            )
          );
        })}
      </div>
      <div className="absolute inset-0 bg-linear-to-t from-black via-black/80 to-black/20" />
      <div className="absolute inset-x-0 top-0 flex justify-end px-6 pt-4">
        <Skip p={p} />
      </div>
      <div className="relative flex flex-col gap-4 px-6 pb-10">
        <p className="font-serif text-headline-s">{p.brand.name}</p>
        <h1 className="font-serif text-display">{t.welcomeTitle}</h1>
        <p className="text-body-l text-white/85">{t.welcomeBody}</p>
        <Button className="mt-2 w-full">{t.start}</Button>
      </div>
    </div>
  );
}
function LanguageStep({ p }: { p: Page }) {
  const { t } = p;
  return (
    <Step p={p} at={1} action={<Button className="w-full">{t.next}</Button>}>
      <h1 className="font-serif text-headline-l">{t.languageTitle}</h1>
      <p className="pt-2 text-text-secondary">{t.languageBody}</p>
      <fieldset aria-label={t.languageTitle} className="flex flex-col gap-3 pt-8">
        {(["Kiswahili", "English"] as const).map((name, i) => {
          const on = (p.locale === "sw") === (i === 0);
          return (
            <label
              key={name}
              className={cx(
                "flex h-20 items-center justify-between rounded-lg border-2 px-5",
                on ? "border-text-primary bg-surface-sunken" : "border-border bg-surface",
              )}
            >
              <input type="radio" name="language" defaultChecked={on} className="sr-only" />
              <span className="font-serif text-headline-m">{name}</span>
              {on && <Check aria-hidden size={24} />}
            </label>
          );
        })}
      </fieldset>
    </Step>
  );
}
function Topics({ p }: { p: Page }) {
  const { t, d } = p;
  const picked = new Set([1, 3, 6, 8]);
  return (
    <Step
      p={p}
      at={2}
      action={
        <>
          <p className="text-center text-caption text-text-secondary">{t.chosen(picked.size)}</p>
          <Button className="w-full">{t.next}</Button>
        </>
      }
    >
      <h1 className="font-serif text-headline-l">{t.topicsTitle}</h1>
      <p className="pt-2 text-text-secondary">{t.topicsBody}</p>
      <ul className="flex flex-wrap gap-2 pt-6">
        {d.navigation.map((n: Topic, i: number) => {
          const Icon = ICONS[n.icon] ?? Newspaper;
          const on = picked.has(i);
          return (
            <li key={n.id}>
              <button
                type="button"
                aria-pressed={on}
                className={cx(
                  "inline-flex h-12 items-center gap-2 rounded-full border px-4 text-label",
                  on ? "border-text-primary bg-text-primary text-bg" : "border-border-strong bg-surface",
                )}
              >
                {on ? <Check aria-hidden size={18} /> : <Icon aria-hidden size={18} />} {n.name}
              </button>
            </li>
          );
        })}
      </ul>
    </Step>
  );
}
function Notify({ p }: { p: Page }) {
  const { t } = p;
  return (
    <Step
      p={p}
      at={3}
      action={
        <>
          <Button className="w-full">{t.notifyYes}</Button>
          <Button variant="ghost" className="w-full">
            {t.notifyNo}
          </Button>
        </>
      }
    >
      <div className="rounded-xl bg-surface-sunken px-5 pt-16 pb-12">
        <div className="flex gap-3 rounded-lg bg-surface-raised p-4 shadow-lg">
          <span className="grid size-10 shrink-0 place-items-center rounded-sm bg-brand text-on-brand">
            <Bell aria-hidden size={20} />
          </span>
          <div className="min-w-0">
            <p className="flex justify-between gap-2 text-caption text-text-secondary">
              <span>{p.brand.name}</span> <span>{t.nowLabel}</span>
            </p>
            <p className="text-label">{t.breaking}</p>
            <p className="text-caption">{t.notifyExample}</p>
          </div>
        </div>
      </div>
      <h1 className="pt-8 font-serif text-headline-l">{t.notifyTitle}</h1>
      <p className="pt-2 text-text-secondary">{t.notifyBody}</p>
    </Step>
  );
}

// ---- states ----
function State({ p, kind, tab }: { p: Page; kind: "empty" | "error" | "offline"; tab: "saved" | "home" }) {
  const { t } = p;
  return (
    <Frame p={p} tab={tab} bare={tab === "saved"}>
      <div className="lg:py-16">
        <Designed
          kind={kind}
          title={t[`${kind}Title`]}
          body={t[`${kind}Body`]}
          action={
            <Button variant={kind === "error" ? "primary" : "secondary"}>
              {kind === "error" ? t.retry : t[kind === "empty" ? "emptyAction" : "offlineAction"]}
            </Button>
          }
        />
      </div>
    </Frame>
  );
}

export const pages: Record<string, (p: Page) => ReactNode> = {
  home: (p) => <Home p={p} />,
  breaking: (p) => <Home p={p} />,
  "tablet-home": (p) => <HomeWide p={p} />,
  "tablet-article": (p) => <ArticleWide p={p} />,
  "home-skeleton": (p) => <Home p={p} loading />,
  article: (p) => <Article p={p} />,
  "article-skeleton": (p) => <Article p={p} loading />,
  auth: (p) => <Article p={p} sheet={<AuthSheet p={p} />} />,
  "auth-code": (p) => <Article p={p} sheet={<AuthSheet p={p} code />} />,
  comments: (p) => <Article p={p} liked sheet={<CommentsSheet p={p} />} />,
  shorts: (p) => <Shorts p={p} />,
  "shorts-skeleton": (p) => <Shorts p={p} loading />,
  video: (p) => <Video p={p} />,
  "video-skeleton": (p) => <Video p={p} loading />,
  live: (p) => <Live p={p} />,
  "live-skeleton": (p) => <Live p={p} loading />,
  category: (p) => <Category p={p} />,
  "category-skeleton": (p) => <Category p={p} loading />,
  search: (p) => <SearchPage p={p} state="start" />,
  "search-results": (p) => <SearchPage p={p} state="results" />,
  "search-skeleton": (p) => <SearchPage p={p} state="loading" />,
  "search-empty": (p) => <SearchPage p={p} state="nothing" />,
  "onboarding-1-welcome": (p) => <Welcome p={p} />,
  "onboarding-2-language": (p) => <LanguageStep p={p} />,
  "onboarding-3-topics": (p) => <Topics p={p} />,
  "onboarding-4-notify": (p) => <Notify p={p} />,
  "saved-empty": (p) => <State p={p} kind="empty" tab="saved" />,
  error: (p) => <State p={p} kind="error" tab="home" />,
  offline: (p) => <State p={p} kind="offline" tab="home" />,
};
export { type Brand, type Page, pageOf } from "./frame";
