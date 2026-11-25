import { Bone } from "@news/ui/base";
import { ChevronRight } from "@news/ui/icons";
import { Picture } from "@news/ui/media";
import {
  type CardData,
  Designed,
  LeadCard,
  type NewsEnv,
  RowCard,
  SectionHeading,
  ShortCard,
  StoryCard,
  TextCard,
  VideoCard,
} from "@news/ui/news";
import type { ReactNode } from "react";
import type { T } from "@/lib/i18n";
import { BUTTON } from "./button";

export const none = (n: number): undefined[] => Array.from({ length: n }, () => undefined);
export type Maybe = CardData | undefined;
export { BUTTON };

export const Rows = ({ list, env }: { list: Maybe[]; env: NewsEnv }) => (
  <ul className="divide-y divide-border">
    {list.map((card, i) => (
      <li key={card?.id ?? i} className="py-4 first:pt-0">
        <RowCard card={card} env={env} />
      </li>
    ))}
  </ul>
);
export const Grid = ({ list, env }: { list: Maybe[]; env: NewsEnv }) => (
  <ul className="grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
    {list.map((card, i) => (
      <li key={card?.id ?? i}>
        {card?.duration_ms ? <VideoCard card={card} env={env} /> : <StoryCard card={card} env={env} />}
      </li>
    ))}
  </ul>
);
export const River = ({
  list,
  env,
  title,
  href,
}: {
  list: Maybe[];
  env: NewsEnv;
  title: string;
  href?: string;
}) => (
  <section aria-label={title} className="lg:border-border lg:border-l lg:pl-8">
    <SectionHeading title={title} href={href} env={env} />
    <ul className="divide-y divide-border">
      {list.map((card, i) => (
        <li key={card?.id ?? i} className="py-3 first:pt-0">
          <TextCard card={card} env={env} />
        </li>
      ))}
    </ul>
  </section>
);
export const Strip = ({ list, env, shorts = false }: { list: Maybe[]; env: NewsEnv; shorts?: boolean }) => (
  <ul
    className={`-mx-4 flex gap-4 overflow-x-auto px-4 scrollbar-none lg:grid lg:gap-6 ${shorts ? "lg:grid-cols-6" : "lg:grid-cols-4"}`}
  >
    {list.map((card, i) => (
      <li key={card?.id ?? i} className={`shrink-0 lg:w-auto ${shorts ? "w-36" : "w-72"}`}>
        {shorts ? <ShortCard card={card} env={env} /> : <VideoCard card={card} env={env} />}
      </li>
    ))}
  </ul>
);

/** A list: lead with two beside it, then rows in two columns at a desk. Lists of any kind share it. */
export function Feed({
  list,
  env,
  next,
  t,
  empty,
  lead = true,
}: {
  list: Maybe[];
  env: NewsEnv;
  next?: string;
  t: T;
  empty: ReactNode;
  lead?: boolean;
}) {
  if (list.length === 0) return empty;
  const rest = lead ? list.slice(3) : list;
  return (
    <>
      {lead && (
        <div className="grid grid-cols-1 gap-x-8 gap-y-6 lg:grid-cols-12">
          <LeadCard card={list[0]} env={env} priority className="lg:col-span-8" />
          <ul className="flex flex-col gap-6 max-lg:divide-y max-lg:divide-border max-lg:gap-0 lg:col-span-4">
            {list.slice(1, 3).map((card, i) => (
              <li key={card?.id ?? i} className="max-lg:py-4">
                <div className="lg:hidden">
                  <RowCard card={card} env={env} />
                </div>
                <div className="max-lg:hidden">
                  <StoryCard card={card} env={env} />
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
      <ul className="grid grid-cols-1 gap-x-12 max-lg:divide-y max-lg:divide-border lg:mt-10 lg:grid-cols-2 lg:gap-y-2 lg:border-border lg:border-t lg:pt-6">
        {rest.map((card, i) => (
          <li key={card?.id ?? i} className="py-4">
            <RowCard card={card} env={env} />
          </li>
        ))}
      </ul>
      <More href={next} t={t} />
    </>
  );
}
export const More = ({ href, t }: { href?: string; t: T }) =>
  href ? (
    <p className="pt-6 text-center">
      <a
        href={href}
        rel="next"
        className="tap inline-flex items-center gap-1 rounded-sm border border-border-strong px-6 text-label hover:bg-surface-sunken"
      >
        {t("olderStories")} <ChevronRight size={16} />
      </a>
    </p>
  ) : null;
export const Nothing = ({ t, home }: { t: T; home: string }) => (
  <Designed
    kind="empty"
    title={t("feedEmptyTitle")}
    body={t("feedEmptyBody")}
    action={
      <a href={home} className={BUTTON}>
        {t("goHome")}
      </a>
    }
  />
);
/** On a phone the bar already says the name of a place: there the heading is for those who listen (S2). */
export const PageHead = ({
  title,
  text,
  hidden = false,
  children,
}: {
  title?: string;
  text?: string;
  hidden?: boolean;
  children?: ReactNode;
}) => (
  <div
    className={
      hidden
        ? "flex flex-col gap-2 max-lg:[&>ul]:py-3 lg:pt-8 lg:pb-4"
        : "flex flex-col gap-2 pt-4 pb-4 lg:pt-8"
    }
  >
    <h1 className={`font-serif text-headline-m lg:text-display ${hidden ? "max-lg:sr-only" : ""}`}>
      {title ?? <Bone className="w-48" />}
    </h1>
    {text && (
      <p
        className={`max-w-prose text-text-secondary max-lg:line-clamp-3 lg:text-body-l ${hidden ? "max-lg:hidden" : ""}`}
      >
        {text}
      </p>
    )}
    {children}
  </div>
);
export { Picture };
