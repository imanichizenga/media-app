import { Bone } from "@news/ui/base";
import { ArticleBody } from "@news/ui/content";
import { address, Picture, type VideoAsset } from "@news/ui/media";
import { LivePill, type NewsEnv, RowCard, SectionHeading } from "@news/ui/news";
import { VideoPlayer, YouTubeFacade } from "@news/ui/player";
import type { ReactNode } from "react";
import type { Article } from "@/lib/api";
import { type T, words } from "@/lib/i18n";
import { contentOf, dateOf } from "@/lib/view";
import { SaveButton, ShareButton, TextSizeButton } from "./client";
import { Frame } from "./frame";
import { type Maybe, none } from "./parts";

const bones = (widths: string[]) => widths.map((w) => <Bone key={w} className={w} />);
const isVideo = (a: Article) => Boolean(a.video || a.youtube_id);

/** What a guest can do with a story. Absent, never disabled: the rest comes with accounts (M4). */
function Tools({ a, t, column = false }: { a?: Article; t: T; column?: boolean }) {
  const each = `tap grid place-items-center text-text-secondary ${
    column ? "w-11 rounded-full hover:bg-surface-sunken" : "h-14 w-full"
  }`;
  return (
    <ul className={column ? "flex flex-col items-center gap-2" : "grid grid-cols-3"}>
      <li>
        <TextSizeButton label={t("textSize")} className={each} />
      </li>
      {(!a || a.engagement.bookmarks) && (
        <li>
          {a ? (
            <SaveButton
              story={{ path: a.path, headline: a.headline, category: a.category.name }}
              save={t("save")}
              unsave={t("unsave")}
              className={each}
            />
          ) : (
            <span className={each} />
          )}
        </li>
      )}
      {(!a || a.engagement.shares) && (
        <li>
          {a ? (
            <ShareButton label={t("share")} done={t("linkCopied")} title={a.headline} className={each} />
          ) : (
            <span className={each} />
          )}
        </li>
      )}
    </ul>
  );
}

function Byline({ a, env, t, zone }: { a?: Article; env: NewsEnv; t: T; zone: string }) {
  const face = a?.authors[0];
  return (
    <div className="flex items-center gap-3 border-border border-y py-3">
      <span className="grid size-11 shrink-0 place-items-center overflow-hidden rounded-full bg-surface-sunken font-serif text-title text-text-secondary">
        {!a ? (
          <span aria-hidden className="bone block! size-full" />
        ) : face?.avatar ? (
          <Picture
            image={face.avatar as never}
            mediaBase={env.mediaBase}
            alt=""
            sizes="44px"
            className="size-full object-cover"
          />
        ) : (
          face?.name.slice(0, 1)
        )}
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-label">
          {a
            ? a.authors.map((p, i) => (
                <span key={p.path}>
                  {i > 0 && ", "}
                  <a href={p.path} rel="author" className="hover:underline">
                    {p.name}
                  </a>
                </span>
              ))
            : bones(["w-32"])}
        </p>
        <p className="text-caption text-text-secondary">
          {a ? (
            <>
              <time dateTime={a.published_at}>{dateOf(a.published_at, env.locale, zone)}</time>
              {" · "}
              {t("minutesRead", { n: Math.max(1, a.reading_minutes) })}
            </>
          ) : (
            bones(["w-48"])
          )}
        </p>
        {a && Date.parse(a.modified_at) - Date.parse(a.published_at) > 60_000 && (
          <p className="text-caption text-text-secondary">
            {t("updatedAt")} <time dateTime={a.modified_at}>{dateOf(a.modified_at, env.locale, zone)}</time>
          </p>
        )}
      </div>
    </div>
  );
}

function Hero({ a, env, t }: { a?: Article; env: NewsEnv; t: T }) {
  const frame = "hero overflow-hidden bg-surface-sunken max-sm:-mx-4 sm:rounded-md";
  if (!a)
    return (
      <div className={frame}>
        <span aria-hidden className="bone block! size-full rounded-none!" />
      </div>
    );
  if (a.video)
    return (
      <div className="max-sm:-mx-4">
        <VideoPlayer
          video={a.video as VideoAsset}
          mediaBase={env.mediaBase}
          playLabel={t("play")}
          errorLabel={t("videoError")}
        />
      </div>
    );
  if (a.youtube_id)
    return (
      <div className="max-sm:-mx-4">
        <YouTubeFacade
          videoId={a.youtube_id}
          title=""
          poster={a.image ? address(env.mediaBase, `${a.image.crops}crop-16x9.jpg`) : undefined}
          interactive
          playLabel={t("play")}
        />
      </div>
    );
  if (!a.image) return null;
  return (
    <figure>
      <div className={frame}>
        {a.is_sensitive ? (
          <details className="group relative size-full">
            <summary className="absolute inset-0 grid place-items-center p-6 text-center text-label text-text-secondary group-open:hidden">
              {a.content_warning || t("sensitive")}
            </summary>
            <HeroPicture a={a} env={env} />
          </details>
        ) : (
          <HeroPicture a={a} env={env} />
        )}
      </div>
      {a.image.credit && (
        <figcaption className="pt-2 text-caption text-text-secondary">{a.image.credit}</figcaption>
      )}
    </figure>
  );
}
const HeroPicture = ({ a, env }: { a: Article; env: NewsEnv }) => (
  <Picture
    image={a.image as never}
    mediaBase={env.mediaBase}
    sizes="(min-width: 1024px) 704px, 100vw"
    priority
    className="size-full object-cover"
  />
);

export function ArticleView({
  a,
  env,
  zone,
  related,
  path,
  other,
  category,
}: {
  a?: Article;
  env: NewsEnv;
  zone: string;
  related: Maybe[];
  path: string;
  other?: string;
  /** Known from the address before the story is. */
  category?: string;
}) {
  const t = words(env.locale);
  const live = a?.type === "live_blog";
  const list = a ? related : none(4);
  const note = (name: string, text: string, tone: string): ReactNode => (
    <p className={`rounded-md border-l-4 px-4 py-3 ${tone}`}>
      <strong className="font-semibold">{name}.</strong> {text}
    </p>
  );
  return (
    <Frame
      locale={env.locale}
      path={path}
      place="home"
      view={env}
      other={other}
      title={a?.category.name ?? category ?? ""}
      section={a ? (a.breadcrumbs[0]?.path ?? a.category.path) : undefined}
      bottom={<Tools a={a} t={t} />}
      reading
    >
      <div className="mx-auto grid max-w-7xl gap-x-8 px-4 pt-4 lg:grid-cols-[4rem_minmax(0,44rem)] lg:justify-center lg:pt-10 xl:grid-cols-[4rem_minmax(0,44rem)_minmax(0,1fr)]">
        <aside className="hidden lg:block">
          <div className="sticky top-8">
            <Tools a={a} t={t} column />
          </div>
        </aside>
        <article className="flex min-w-0 flex-col gap-5 lg:gap-6" data-page="article">
          <header className="flex flex-col gap-3 lg:gap-4">
            <p className="flex items-center gap-2 text-label">
              {a?.is_live && <LivePill label={t("live")} />}
              {a ? (
                <a href={a.category.path} className="font-semibold hover:underline">
                  {a.category.name}
                </a>
              ) : (
                (category ?? bones(["w-24"]))
              )}
            </p>
            <h1 className="font-serif text-headline-l lg:text-display">
              {a ? a.headline : bones(["w-full", "w-2/3"])}
            </h1>
            {(!a || a.standfirst) && (
              <p className="text-body-l text-text-secondary lg:text-headline-s lg:font-normal!">
                {a ? a.standfirst : bones(["w-full", "w-1/2"])}
              </p>
            )}
            <Byline a={a} env={env} t={t} zone={zone} />
          </header>
          <Hero a={a} env={env} t={t} />
          {a ? (
            <>
              {a.correction_note &&
                note(t("correction"), a.correction_note, "border-warning bg-warning-soft text-warning")}
              {a.update_note &&
                note(t("updateNote"), a.update_note, "border-border-strong bg-surface-sunken")}
              {a.content_warning &&
                !a.is_sensitive &&
                note(t("sensitive"), a.content_warning, "border-border-strong bg-surface-sunken")}
              {live && a.live_ended_at && (
                <p className="rounded-md bg-surface-sunken px-4 py-3 text-label">{t("liveEnded")}</p>
              )}
              <div className="reads" data-body>
                <ArticleBody document={a.body} context={contentOf(a, env)} />
              </div>
              {a.story && (
                <a
                  href={a.story.path}
                  className="block rounded-md border border-border p-4 hover:bg-surface-sunken"
                >
                  <span className="block text-caption text-text-secondary">{t("stories")}</span>
                  <span className="text-title">{a.story.title}</span>
                </a>
              )}
              {a.tags.length > 0 && (
                <ul className="flex flex-wrap gap-2 border-border border-t pt-5">
                  {a.tags.map((tag) => (
                    <li key={tag.slug}>
                      <a
                        href={tag.path}
                        className="tap inline-flex items-center rounded-full border border-border px-4 text-label hover:bg-surface-sunken"
                      >
                        {tag.name}
                      </a>
                    </li>
                  ))}
                </ul>
              )}
            </>
          ) : (
            <ArticleBody.Skeleton />
          )}
          {list.length > 0 && (
            <section aria-label={t("readAlso")} className="pt-4 xl:hidden">
              <SectionHeading title={t("readAlso")} env={env} />
              <Related list={list} env={env} />
            </section>
          )}
        </article>
        {list.length > 0 && (
          // Beside the story only where there is room for a row card (from 1280); under it before that.
          <aside aria-label={t("readAlso")} className="hidden xl:block xl:pl-8">
            <SectionHeading title={t("readAlso")} env={env} />
            <Related list={list} env={env} />
          </aside>
        )}
      </div>
    </Frame>
  );
}
const Related = ({ list, env }: { list: Maybe[]; env: NewsEnv }) => (
  <ul className="divide-y divide-border">
    {list.slice(0, 6).map((card, i) => (
      <li key={card?.id ?? i} className="py-4 first:pt-0">
        <RowCard card={card} env={env} />
      </li>
    ))}
  </ul>
);

export { isVideo };
