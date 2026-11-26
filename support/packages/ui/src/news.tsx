import type { ReactNode } from "react";
import { Bone, cx } from "./base";
import {
  Bookmark,
  ChevronRight,
  Heart,
  type Icon,
  Images,
  MessageSquareQuote,
  Play,
  Share2,
  Zap,
} from "./icons";
import { type ImageAsset, Picture, type VideoAsset } from "./media";

/** What a card needs. The public API's `Card` fits. */
export type CardData = {
  id: string;
  type: string;
  path: string;
  headline: string;
  standfirst: string;
  category: { name: string; path: string };
  authors: { name: string }[];
  image: ImageAsset | null;
  video: VideoAsset | null;
  duration_ms: number | null;
  reading_minutes: number;
  published_at: string;
  breaking_until: string | null;
  is_live: boolean;
  is_sensitive: boolean;
};
export type NewsLabels = {
  live: string;
  breaking: string;
  gallery: string;
  sensitive: string;
  minutes: (n: number) => string;
  more: string;
};
export type NewsEnv = {
  locale: "sw" | "en";
  mediaBase: string;
  /** Fixed for a whole page, so the server and the browser agree on "five minutes ago". */
  now: number;
  t: NewsLabels;
};

const MINUTE = 60_000;
/** "dakika 5 zilizopita", then a date. Never a lie: the exact time is in the `datetime` attribute. */
export function ago(iso: string, { now, locale }: Pick<NewsEnv, "now" | "locale">): string {
  const past = Math.max(0, now - Date.parse(iso));
  const format = new Intl.RelativeTimeFormat(locale, { style: locale === "en" ? "narrow" : "long" });
  if (past < 60 * MINUTE) return format.format(-Math.max(1, Math.round(past / MINUTE)), "minute");
  if (past < 24 * 60 * MINUTE) return format.format(-Math.round(past / (60 * MINUTE)), "hour");
  return new Intl.DateTimeFormat(locale === "en" ? "en-GB" : "sw", {
    day: "numeric",
    month: "short",
    timeZone: "Africa/Dar_es_Salaam",
  }).format(Date.parse(iso));
}
/**
 * 1.3K, 3.4M. The same letters in both languages: CLDR's Swahili short form ("elfu 1.3") is too wide for an action
 * bar, and readers know K and M from every other app (ADR-0034).
 */
export const compact = (n: number, _locale: NewsEnv["locale"]) =>
  new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 }).format(n);
/** The whole number, for those who listen. */
export const exact = (n: number, locale: NewsEnv["locale"]) => new Intl.NumberFormat(locale).format(n);
/** 0:08, 12:30, 1:02:05. */
export function clock(ms: number): string {
  const s = Math.round(ms / 1000);
  const two = (n: number) => String(n).padStart(2, "0");
  const h = Math.floor(s / 3600);
  const m = Math.floor(s / 60) % 60;
  return h > 0 ? `${h}:${two(m)}:${two(s % 60)}` : `${m}:${two(s % 60)}`;
}

/** The other way: "12:30" → 750. What cannot be read is zero. */
export function seconds(text: string): number {
  const parts = text.trim().split(":");
  if (parts.length > 3 || !parts.every((p) => /^\d{1,3}$/.test(p))) return 0;
  return Math.min(
    86_400,
    parts.reduce((total, p) => total * 60 + Number(p), 0),
  );
}

// ---- small pieces ----
export type Logo = { width: number; height: number; svg: string; png: Record<string, string> };
/** The logo when there is one, or the name set in the serif. An <img>, always: an uploaded SVG is never inlined. */
export function Wordmark({
  name,
  light,
  dark,
  base = "",
  className,
}: {
  name: string;
  light?: Logo | null;
  dark?: Logo | null;
  base?: string;
  className?: string;
}) {
  if (!light) return <span className={cx("font-serif text-wordmark", className)}>{name}</span>;
  const image = (logo: Logo, show: string) => (
    <img
      src={base + (logo.svg || logo.png["1x"])}
      srcSet={logo.svg ? undefined : ["1x", "2x", "3x"].map((d) => `${base}${logo.png[d]} ${d}`).join(", ")}
      alt={name}
      width={Math.round((32 * logo.width) / logo.height)}
      height={32}
      className={cx("h-8 w-auto", show, className)}
    />
  );
  return (
    <>
      {image(light, "on-light")}
      {dark && image(dark, "on-dark")}
    </>
  );
}
export const LivePill = ({ label, className }: { label: string; className?: string }) => (
  <span
    className={cx(
      "inline-flex items-center gap-1 rounded-full bg-signal-live px-2 py-0.5 text-caption font-semibold text-on-signal-live",
      className,
    )}
  >
    <span aria-hidden className="size-1.5 rounded-full bg-current motion-safe:animate-pulse" />
    {label}
  </span>
);
/**
 * What a card is about and how fresh it is: one line, always, and nothing in it cut (ADR-0044, R2). In order of what
 * matters: the category, whole; the time; the reading time. The line is one line high and its parts wrap whole onto a
 * hidden second line, so without script the reading time goes first, then the time. With script (islands/site.ts),
 * when the time has gone the category takes the short name its editor gave it, and the time comes back.
 */
export function Kicker({
  card,
  env,
  quiet = false,
  reading = false,
  cover = false,
}: {
  card?: CardData;
  env: NewsEnv;
  quiet?: boolean;
  /** Over the lead's picture on a phone, where the picture's own corner is taken. */
  cover?: boolean;
  /** Also how long it takes to read. */
  reading?: boolean;
}) {
  if (!card)
    return (
      <p className="text-caption">
        <Bone className="w-28" />
      </p>
    );
  const breaking = card.breaking_until !== null && Date.parse(card.breaking_until) > env.now;
  const pill = card.is_live && (cover || !quiet);
  const named = !(card.is_live && !quiet && !cover);
  const name = breaking ? env.t.breaking : card.category.name;
  const short = breaking ? "" : (card.category.short_name ?? "");
  return (
    <p
      data-meta=""
      className="meta flex h-[1lh] min-w-0 flex-wrap items-center gap-x-1.5 overflow-hidden text-caption text-text-secondary"
    >
      {pill && <LivePill label={env.t.live} className={cx("shrink-0", cover ? "lg:hidden" : "")} />}
      {named && (
        <span className="shrink-0 whitespace-nowrap font-semibold text-text-primary">
          <span data-name="">{name}</span>
          {short && short !== name && (
            <span data-short="" hidden>
              {short}
            </span>
          )}
        </span>
      )}
      <span data-time="" className="shrink-0 whitespace-nowrap">
        <span aria-hidden>· </span>
        <time dateTime={card.published_at}>{ago(card.published_at, env)}</time>
      </span>
      {reading && !card.is_live && (
        <span data-reading="" className="shrink-0 whitespace-nowrap">
          <span aria-hidden>· </span>
          {env.t.minutes(Math.max(1, card.reading_minutes))}
        </span>
      )}
    </p>
  );
}
const VIDEO = new Set(["video", "short", "youtube"]);
/** Says what opens, in a corner of the picture. */
function Mark({ card, env, className }: { card: CardData; env: NewsEnv; className?: string }) {
  if (card.is_live) return null; // the LIVE pill says it
  const [Sign, label]: [Icon | null, string] =
    VIDEO.has(card.type) && card.duration_ms
      ? [Play, clock(card.duration_ms)]
      : card.type === "gallery"
        ? [Images, env.t.gallery]
        : [null, ""];
  if (!Sign) return null;
  return (
    <span
      className={cx(
        "absolute bottom-2 left-2 inline-flex items-center gap-1 rounded-sm bg-black/75 px-2 py-0.5 text-caption text-white",
        className,
      )}
    >
      <Sign size={14} fill={Sign === Play ? "currentColor" : "none"} /> {label}
    </span>
  );
}
/** The frame fixes the shape, so nothing moves when the picture comes. */
function Frame({
  card,
  env,
  ratio,
  sizes,
  priority,
  plain = false,
  covered = false,
  className,
}: {
  card?: CardData;
  env: NewsEnv;
  ratio: string;
  sizes: string;
  priority?: boolean;
  plain?: boolean;
  /** Marks at a desk only. */
  covered?: boolean;
  className?: string;
}) {
  const corner = covered ? "max-lg:hidden" : undefined;
  return (
    <div className={cx("relative overflow-hidden rounded-md bg-surface-sunken", ratio, className)}>
      {card ? (
        <>
          {card.image && (
            <Picture
              image={card.image}
              mediaBase={env.mediaBase}
              alt=""
              sizes={sizes}
              priority={priority}
              className={cx("size-full object-cover", card.is_sensitive && "blur-2xl")}
            />
          )}
          {card.is_sensitive && (
            <span className="absolute inset-0 grid place-items-center p-2 text-center text-caption text-white">
              {env.t.sensitive}
            </span>
          )}
          {!plain && <Mark card={card} env={env} className={corner} />}
          {!plain && card.is_live && (
            <LivePill label={env.t.live} className={cx("absolute bottom-2 left-2", corner)} />
          )}
        </>
      ) : (
        <span aria-hidden className="bone block! size-full rounded-none!" />
      )}
    </div>
  );
}
const lines = (widths: string[]) => widths.map((w) => <Bone key={w} className={w} />);
/** One link per card, stretched over it: one stop for the keyboard, one target for the thumb. */
function Headline({
  card,
  className,
  level = 3,
  bones,
}: {
  card?: CardData;
  className: string;
  level?: 2 | 3;
  bones: string[];
}) {
  const Tag = level === 2 ? "h2" : "h3";
  return (
    <Tag className={cx("font-serif text-balance break-words", className)}>
      {card ? (
        <a
          href={card.path}
          className="after:absolute after:inset-0 group-hover:underline group-hover:decoration-1 group-hover:underline-offset-4"
        >
          {card.headline}
        </a>
      ) : (
        lines(bones)
      )}
    </Tag>
  );
}
type CardProps = { card?: CardData; env: NewsEnv; priority?: boolean; className?: string };

// ---- cards ----
/**
 * The one story of the page. On a phone the words stand on the picture, so that all of them are above the bar (S1); at
 * a desk they stand under it.
 */
export function LeadCard({ card, env, priority, play = false, className }: CardProps & { play?: boolean }) {
  return (
    <article
      className={cx(
        "group relative flex flex-col gap-3 max-lg:-mx-4 max-lg:overflow-hidden max-lg:bg-black",
        className,
      )}
      data-card="lead"
    >
      <Frame
        card={card}
        env={env}
        ratio={play ? "aspect-4/3 lg:aspect-video" : "aspect-video lead-tall"}
        sizes="(min-width: 1024px) 640px, 100vw"
        priority={priority}
        covered
        className="max-lg:rounded-none"
      />
      <div
        className={cx(
          "flex flex-col gap-1 lg:gap-3",
          "max-lg:absolute max-lg:inset-x-0 max-lg:bottom-0 max-lg:p-4 max-lg:pt-16",
          card &&
            "cover max-lg:bg-linear-to-t max-lg:from-black/90 max-lg:via-black/70 max-lg:to-transparent",
        )}
      >
        <Kicker card={card} env={env} quiet reading cover />
        <Headline
          card={card}
          level={2}
          className="text-headline-m max-lg:leading-[1.2]! lg:text-display"
          bones={["w-full", "w-2/3"]}
        />
        <p className="text-body-l text-text-secondary max-lg:hidden">
          {card ? card.standfirst : lines(["w-full", "w-1/2"])}
        </p>
      </div>
    </article>
  );
}
/** Picture above, for grids. */
export function StoryCard({ card, env, className }: CardProps) {
  return (
    <article className={cx("group relative flex flex-col gap-2", className)} data-card="story">
      <Frame card={card} env={env} ratio="aspect-3/2" sizes="(min-width: 1024px) 300px, 50vw" />
      <Kicker card={card} env={env} quiet />
      <Headline card={card} className="text-headline-s" bones={["w-full", "w-3/4"]} />
    </article>
  );
}
/** Picture beside, for lists: the everyday card on a phone. */
export function RowCard({ card, env, className }: CardProps) {
  return (
    <article className={cx("group relative flex items-start gap-4", className)} data-card="row">
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <Kicker card={card} env={env} />
        <Headline card={card} className="text-headline-s line-clamp-3" bones={["w-full", "w-2/3"]} />
      </div>
      <Frame card={card} env={env} ratio="aspect-4/3" sizes="112px" plain className="w-28 shrink-0" />
    </article>
  );
}
/** Words only, for the river of latest news. */
export function TextCard({ card, env, className }: CardProps) {
  return (
    <article className={cx("group relative flex flex-col gap-1", className)} data-card="text">
      <Kicker card={card} env={env} />
      <Headline card={card} className="text-title font-medium!" bones={["w-full", "w-1/2"]} />
    </article>
  );
}
export function VideoCard({ card, env, className }: CardProps) {
  return (
    <article className={cx("group relative flex flex-col gap-2", className)} data-card="video">
      <Frame card={card} env={env} ratio="aspect-video" sizes="(min-width: 1024px) 300px, 75vw" />
      <Kicker card={card} env={env} quiet />
      <Headline card={card} className="text-title" bones={["w-full", "w-2/3"]} />
    </article>
  );
}
export function ShortCard({ card, env, className }: CardProps) {
  return (
    <article className={cx("group relative overflow-hidden rounded-md", className)} data-card="short">
      <Frame card={card} env={env} ratio="aspect-9/16" sizes="200px" plain />
      {card && (
        <div className="absolute inset-x-0 bottom-0 bg-linear-to-t from-black/85 to-transparent p-3 pt-12 text-white">
          <h3 className="line-clamp-3 text-label">
            <a href={card.path} className="after:absolute after:inset-0">
              {card.headline}
            </a>
          </h3>
          {card.duration_ms && <p className="text-caption">{clock(card.duration_ms)}</p>}
        </div>
      )}
    </article>
  );
}

// ---- groups ----
export function SectionHeading({ title, href, env }: { title?: string; href?: string; env: NewsEnv }) {
  return (
    <div className="mb-5 flex items-center justify-between border-text-primary border-t-2 pt-3">
      <h2 className="font-serif text-headline-m">{title ?? <Bone className="w-32" />}</h2>
      {href && (
        <a
          href={href}
          className="tap -my-2 inline-flex items-center gap-1 text-label text-text-secondary hover:text-text-primary"
        >
          {env.t.more} <ChevronRight aria-hidden size={16} />
        </a>
      )}
    </div>
  );
}
/** Circles with a ring, a shape nothing else has: something is happening now. Absent when nothing is. */
export function LiveRail({ cards, env, title }: { cards?: CardData[]; env: NewsEnv; title: string }) {
  if (cards?.length === 0) return null;
  return (
    <section
      aria-label={title}
      className="-mx-4 h-24 overflow-x-auto overflow-y-hidden px-4 scrollbar-none lg:h-28"
    >
      <ul className="flex gap-2 pt-2 lg:gap-4">
        {(cards ?? Array.from({ length: 4 }, () => undefined)).map((card, i) => (
          <li key={card?.id ?? i} className="group relative w-20 shrink-0 text-center lg:w-24">
            <span
              className={cx(
                "relative mx-auto block size-14 rounded-full border-2 p-0.5 lg:size-18",
                card ? "border-signal-live" : "border-border",
              )}
            >
              <span className="block size-full overflow-hidden rounded-full bg-surface-sunken">
                {card?.image ? (
                  <Picture
                    image={card.image}
                    mediaBase={env.mediaBase}
                    alt=""
                    sizes="80px"
                    className="size-full object-cover"
                  />
                ) : (
                  <span aria-hidden className="bone block! size-full" />
                )}
              </span>
            </span>
            {/* Two lines (R3): the editor's rail title, or the headline cut between words by the server. */}
            <span className="rail-title mt-1 block text-[0.75rem] leading-[1.15]">
              {card ? (
                <a href={card.path} className="after:absolute after:inset-0">
                  <span className="sr-only">
                    {env.t.live}: {card.headline}
                  </span>
                  <span aria-hidden>{card.rail_title || card.headline}</span>
                </a>
              ) : (
                lines(["w-full", "w-2/3"])
              )}
            </span>
          </li>
        ))}
      </ul>
    </section>
  );
}
/** Absent, not empty, when there is no breaking news. */
export function BreakingBanner({ card, env }: { card?: CardData; env: NewsEnv }) {
  if (!card) return null;
  return (
    <a href={card.path} className="block bg-signal-breaking-bg text-signal-breaking-fg">
      <span className="mx-auto flex h-12 max-w-7xl items-center gap-2 px-4">
        <Zap size={16} fill="currentColor" className="shrink-0 text-signal-breaking-label" />
        <span className="min-w-0 flex-1 truncate">
          <strong className="mr-2 font-semibold text-caption text-signal-breaking-label tracking-wide uppercase">
            {env.t.breaking}
          </strong>
          <span className="text-label">{card.headline}</span>
        </span>
        <ChevronRight aria-hidden size={18} className="shrink-0" />
      </span>
    </a>
  );
}

// ---- engagement (M4): only what the policy allows is ever passed in ----
export type Action = { key: string; label: string; icon: Icon; count?: number; active?: boolean };
export const ACTIONS = { like: Heart, comment: MessageSquareQuote, bookmark: Bookmark, share: Share2 };
export function ActionBar({
  actions,
  locale,
  vertical = false,
  className,
}: {
  actions: Action[];
  locale: NewsEnv["locale"];
  vertical?: boolean;
  className?: string;
}) {
  return (
    <ul className={cx("flex", vertical ? "flex-col items-center gap-2" : "justify-around", className)}>
      {actions.map(({ key, label, icon: Icon, count, active }) => (
        <li key={key}>
          <button
            type="button"
            aria-label={count === undefined ? label : `${label}, ${exact(count, locale)}`}
            aria-pressed={active}
            className={cx(
              "tap inline-flex items-center justify-center gap-1.5 rounded-sm px-3 text-label hover:bg-surface-sunken",
              vertical && "flex-col gap-0.5! py-1.5",
              active ? (key === "like" ? "text-liked" : "text-text-primary") : "text-text-secondary",
            )}
          >
            <Icon aria-hidden size={22} fill={active ? "currentColor" : "none"} />
            {count !== undefined && <span className="tabular-nums">{compact(count, locale)}</span>}
          </button>
        </li>
      ))}
    </ul>
  );
}

// ---- designed emptiness ----
const DRAWINGS: Record<string, ReactNode> = {
  empty: (
    <>
      <path d="M34 30h52a6 6 0 0 1 6 6v56l-32-18-32 18V36a6 6 0 0 1 6-6Z" />
      <path d="M46 46h28M46 56h18" />
    </>
  ),
  error: (
    <>
      <rect x="22" y="30" width="76" height="60" rx="6" />
      <path d="M22 46h76M34 60h20M34 70h34M78 58l12 12M90 58 78 70" />
    </>
  ),
  offline: (
    <>
      <path d="M26 56a50 50 0 0 1 68 0M38 68a33 33 0 0 1 44 0M50 80a16 16 0 0 1 20 0" />
      <path d="M28 96 92 28" />
    </>
  ),
};
export function Designed({
  kind,
  title,
  body,
  action,
  level = 2,
}: {
  kind: "empty" | "error" | "offline";
  /** 1 when it is the whole page. */
  level?: 1 | 2;
  title: string;
  body: string;
  action: ReactNode;
}) {
  const Title = level === 1 ? "h1" : "h2";
  return (
    <div className="mx-auto flex max-w-sm flex-col items-center gap-3 px-4 py-16 text-center">
      <svg aria-hidden="true" viewBox="0 0 120 120" className="size-32 text-text-secondary">
        <circle cx="60" cy="60" r="56" fill="var(--color-surface-sunken)" />
        <g fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          {DRAWINGS[kind]}
        </g>
      </svg>
      <Title className="font-serif text-headline-m">{title}</Title>
      <p className="text-text-secondary">{body}</p>
      <div className="pt-2">{action}</div>
    </div>
  );
}
