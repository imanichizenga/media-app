import {
  Bookmark,
  ChevronRight,
  Heart,
  Images,
  type LucideIcon,
  MessageCircle,
  Play,
  Radio,
  Share2,
} from "lucide-react";
import type { ReactNode } from "react";
import { type ImageAsset, Picture, type VideoAsset } from "./media";
import { Bone, cx } from "./primitives";

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
  reading_minutes: number;
  published_at: string;
  breaking_until: string | null;
  is_live: boolean;
  is_sensitive: boolean;
};
export type NewsLabels = {
  live: string;
  breaking: string;
  video: string;
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
/** 1.2K, 3.4M, in the reader's language. */
export const compact = (n: number, locale: NewsEnv["locale"]) =>
  new Intl.NumberFormat(locale, { notation: "compact", maximumFractionDigits: 1 }).format(n);
export const clock = (ms: number) =>
  `${Math.floor(ms / 60_000)}:${String(Math.floor(ms / 1000) % 60).padStart(2, "0")}`;

// ---- small pieces ----
export const LivePill = ({ label, className }: { label: string; className?: string }) => (
  <span
    className={cx(
      "inline-flex items-center gap-1 rounded-sm bg-live px-2 py-0.5 text-caption font-semibold text-on-live",
      className,
    )}
  >
    <span aria-hidden className="size-1.5 rounded-full bg-current motion-safe:animate-pulse" />
    {label}
  </span>
);
/** What a card is about and how fresh it is: always the first line, always in this order. */
function Kicker({ card, env }: { card?: CardData; env: NewsEnv }) {
  if (!card)
    return (
      <p className="text-caption">
        <Bone className="w-28" />
      </p>
    );
  const breaking = card.breaking_until !== null && Date.parse(card.breaking_until) > env.now;
  return (
    <p className="flex flex-wrap items-center gap-x-2 text-caption text-text-secondary">
      {card.is_live ? (
        <LivePill label={env.t.live} />
      ) : breaking ? (
        <span className="font-semibold text-live">{env.t.breaking}</span>
      ) : (
        <span className="font-semibold text-accent">{card.category.name}</span>
      )}
      <span aria-hidden>·</span>
      <time dateTime={card.published_at}>{ago(card.published_at, env)}</time>
    </p>
  );
}
const VIDEO = new Set(["video", "short", "youtube"]);
/** Says what opens, in a corner of the picture. */
function Mark({ card, env }: { card: CardData; env: NewsEnv }) {
  const [Icon, label]: [LucideIcon | null, string] = VIDEO.has(card.type)
    ? [Play, card.video?.duration_ms ? clock(card.video.duration_ms) : env.t.video]
    : card.type === "gallery"
      ? [Images, env.t.gallery]
      : [null, ""];
  if (!Icon) return null;
  return (
    <span className="absolute bottom-2 left-2 inline-flex items-center gap-1 rounded-sm bg-black/75 px-2 py-0.5 text-caption text-white">
      <Icon aria-hidden size={14} fill={Icon === Play ? "currentColor" : "none"} /> {label}
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
  className,
}: {
  card?: CardData;
  env: NewsEnv;
  ratio: string;
  sizes: string;
  priority?: boolean;
  plain?: boolean;
  className?: string;
}) {
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
          {!plain && <Mark card={card} env={env} />}
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
    <Tag className={cx("font-serif text-balance", className)}>
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
/** The one story of the page. */
export function LeadCard({ card, env, priority, className }: CardProps) {
  return (
    <article className={cx("group relative flex flex-col gap-3", className)} data-card="lead">
      <Frame
        card={card}
        env={env}
        ratio="aspect-video"
        sizes="(min-width: 1024px) 640px, 100vw"
        priority={priority}
        className="max-sm:-mx-4 max-sm:rounded-none"
      />
      <Kicker card={card} env={env} />
      <Headline
        card={card}
        level={2}
        className="text-headline-l lg:text-display"
        bones={["w-full", "w-2/3"]}
      />
      <p className="text-body-l text-text-secondary">{card ? card.standfirst : lines(["w-full", "w-1/2"])}</p>
      <p className="text-caption text-text-secondary">
        {card ? (
          <>
            {card.authors.map((a) => a.name).join(", ")} · {env.t.minutes(card.reading_minutes)}
          </>
        ) : (
          <Bone className="w-40" />
        )}
      </p>
    </article>
  );
}
/** Picture above, for grids. */
export function StoryCard({ card, env, className }: CardProps) {
  return (
    <article className={cx("group relative flex flex-col gap-2", className)} data-card="story">
      <Frame card={card} env={env} ratio="aspect-3/2" sizes="(min-width: 1024px) 300px, 50vw" />
      <Kicker card={card} env={env} />
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
      <Headline card={card} className="text-title" bones={["w-full", "w-2/3"]} />
      <Kicker card={card} env={env} />
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
          {card.video?.duration_ms && <p className="text-caption">{clock(card.video.duration_ms)}</p>}
        </div>
      )}
    </article>
  );
}

// ---- groups ----
export function SectionHeading({
  title,
  href,
  env,
  icon: Icon,
}: {
  title?: string;
  href?: string;
  env: NewsEnv;
  icon?: LucideIcon;
}) {
  return (
    <div className="mb-5 flex items-center justify-between border-text-primary border-t-2 pt-3">
      <h2 className="flex items-center gap-2 font-serif text-headline-m">
        {Icon && <Icon aria-hidden size={22} className="text-live" />}
        {title ?? <Bone className="w-32" />}
      </h2>
      {href && (
        <a
          href={href}
          className="tap -my-2 inline-flex items-center gap-1 text-label text-accent hover:underline"
        >
          {env.t.more} <ChevronRight aria-hidden size={16} />
        </a>
      )}
    </div>
  );
}
/** Circles with a red ring: something is happening now. Absent when nothing is. */
export function LiveRail({ cards, env, title }: { cards?: CardData[]; env: NewsEnv; title: string }) {
  if (cards?.length === 0) return null;
  return (
    <section aria-label={title} className="-mx-4 overflow-x-auto px-4 scrollbar-none">
      <ul className="flex gap-4">
        {(cards ?? Array.from({ length: 4 }, () => undefined)).map((card, i) => (
          <li key={card?.id ?? i} className="group relative w-28 shrink-0 text-center">
            <span
              className={cx(
                "relative mx-auto block size-20 rounded-full border-2 p-1",
                card ? "border-live" : "border-border",
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
              {card && (
                <LivePill
                  label={env.t.live}
                  className="-bottom-2 -translate-x-1/2 absolute left-1/2 whitespace-nowrap px-1.5! leading-4! [&>span]:hidden"
                />
              )}
            </span>
            <span className="mt-3 line-clamp-2 text-caption">
              {card ? (
                <a href={card.path} className="after:absolute after:inset-0">
                  {card.headline}
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
    <a href={card.path} className="block bg-live text-on-live">
      <span className="mx-auto flex max-w-7xl items-center gap-3 px-4 py-3">
        <Radio aria-hidden size={20} className="shrink-0 motion-safe:animate-pulse" />
        <span className="min-w-0 flex-1">
          <strong className="mr-2 font-semibold text-caption tracking-wide uppercase">
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
export type Action = { key: string; label: string; icon: LucideIcon; count?: number; active?: boolean };
export const ACTIONS = { like: Heart, comment: MessageCircle, bookmark: Bookmark, share: Share2 };
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
            aria-label={count === undefined ? label : `${label}, ${count}`}
            aria-pressed={active}
            className={cx(
              "tap inline-flex items-center justify-center gap-1.5 rounded-sm px-3 text-label hover:bg-surface-sunken",
              vertical && "flex-col gap-0.5! py-1.5",
              active ? "text-accent" : "text-text-secondary",
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
}: {
  kind: "empty" | "error" | "offline";
  title: string;
  body: string;
  action: ReactNode;
}) {
  return (
    <div className="mx-auto flex max-w-sm flex-col items-center gap-3 px-4 py-16 text-center">
      <svg aria-hidden="true" viewBox="0 0 120 120" className="size-32 text-accent">
        <circle cx="60" cy="60" r="56" fill="var(--color-accent-soft)" />
        <g fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          {DRAWINGS[kind]}
        </g>
      </svg>
      <h2 className="font-serif text-headline-m">{title}</h2>
      <p className="text-text-secondary">{body}</p>
      <div className="pt-2">{action}</div>
    </div>
  );
}
