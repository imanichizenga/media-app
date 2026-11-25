import { ArrowRight, Play, Volume2, VolumeX } from "@news/ui/icons";
import type { ReactNode } from "react";
import { words } from "@/lib/i18n";
import type { Locale } from "@/lib/locale";
import { SaveButton, ShareButton } from "./client";
import { Places } from "./frame";
import { VideoTabs } from "./video-tabs";

export type Short = {
  id: string;
  path: string;
  headline: string;
  category: string;
  when: string;
  at: string;
  hls: string;
  poster: string;
};
type Words = Record<
  "mute" | "unmute" | "play" | "pause" | "save" | "unsave" | "share" | "shared" | "open" | "error",
  string
>;
const ROUND = "tap grid w-11 place-items-center rounded-full";

export const ShortsFeed = ({ list, words }: { list: Short[]; words: Words }) => (
  <ul
    data-shorts
    className="mx-auto flex min-h-0 w-full flex-1 snap-y snap-mandatory flex-col overflow-y-auto overscroll-contain scrollbar-none lg:aspect-9/16 lg:w-auto lg:gap-4"
  >
    {list.map((short, i) => (
      <li
        key={short.id}
        data-hls={short.hls}
        className="group relative h-full shrink-0 snap-start snap-always overflow-hidden bg-neutral-900 lg:rounded-xl"
      >
        <video
          poster={i < 2 ? short.poster || undefined : undefined}
          data-poster={short.poster || undefined}
          loop
          muted
          playsInline
          preload="none"
          aria-label={short.headline}
          className="absolute inset-0 size-full object-cover"
        />
        <button
          type="button"
          aria-label={words.play}
          data-do="short"
          data-play={words.play}
          data-pause={words.pause}
          className="absolute inset-0 grid place-items-center"
        >
          <span
            data-sign
            className="hidden size-16 place-items-center rounded-full bg-black/60 group-data-stopped:grid"
          >
            <Play size={28} fill="currentColor" />
          </span>
        </button>
        <button
          type="button"
          aria-label={words.unmute}
          data-do="mute"
          data-mute={words.mute}
          data-unmute={words.unmute}
          className={`${ROUND} absolute top-3 right-3 z-20 bg-black/50`}
        >
          <VolumeX size={20} className="in-data-sound:hidden" />
          <Volume2 size={20} className="not-in-data-sound:hidden" />
        </button>
        <div className="pointer-events-none absolute inset-x-0 bottom-0 flex items-end gap-3 bg-linear-to-t from-black/90 via-black/50 to-transparent p-4 pt-40">
          <div className="pointer-events-auto min-w-0 flex-1">
            <p className="flex min-w-0 gap-1.5 whitespace-nowrap text-caption">
              <span className="min-w-0 truncate font-semibold">{short.category}</span>
              <span aria-hidden>·</span>
              <time dateTime={short.at} className="shrink-0">
                {short.when}
              </time>
            </p>
            <h2 className="line-clamp-3 py-1 font-serif text-headline-s">{short.headline}</h2>
            <a href={short.path} className="tap inline-flex items-center gap-1 text-label">
              {words.open} <ArrowRight size={16} />
            </a>
          </div>
          <div className="pointer-events-auto flex flex-col gap-2 drop-shadow-[0_1px_3px_rgb(0_0_0/0.85)]">
            <SaveButton
              story={short}
              save={words.save}
              unsave={words.unsave}
              className={ROUND}
              on="aria-pressed:text-liked-on-dark"
            />
            <ShareButton
              label={words.share}
              done={words.shared}
              title={short.headline}
              path={short.path}
              className={ROUND}
            />
          </div>
        </div>
        <p
          role="alert"
          hidden
          data-failed
          className="absolute inset-x-0 top-1/2 bg-black/80 p-3 text-center text-label [[hidden]]:hidden"
        >
          {words.error}
        </p>
      </li>
    ))}
  </ul>
);

/** Always dark, in every theme, with nothing but its overlay (N4, N7). */
export const ShortsFrame = ({ locale, children }: { locale: Locale; children: ReactNode }) => (
  <div className="flex h-dvh flex-col bg-black text-white" data-page="shorts">
    <main id="main" className="relative flex min-h-0 flex-1 flex-col lg:py-6">
      <h1 className="sr-only">{words(locale)("shorts")}</h1>
      <div className="absolute inset-x-0 top-0 z-10 bg-linear-to-b from-black/70 to-transparent pb-8 lg:top-6">
        <VideoTabs locale={locale} open="shorts" onDark />
      </div>
      {children}
    </main>
    <div className="border-white/15 border-t bg-black pb-[env(safe-area-inset-bottom)]" data-bar>
      <Places locale={locale} place="video" onDark />
    </div>
  </div>
);
export const ShortsBones = () => (
  <span
    aria-hidden
    className="mx-auto size-full flex-1 animate-pulse bg-white/10 lg:aspect-9/16 lg:w-auto lg:rounded-xl"
  />
);
