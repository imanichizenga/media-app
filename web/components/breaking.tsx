import { Pause, Play, Zap } from "@news/ui/icons";
import { ago, type CardData, type NewsEnv } from "@news/ui/news";
import type { T } from "@/lib/i18n";

/**
 * Breaking news, first on every page, under the fixed top: the label with a beating dot, the whole headline, how long
 * ago. When there are several, they take turns (islands/site.ts): all are laid in one grid cell, so the bar is as tall
 * as the longest and never changes height while they turn. Turning stops under the pointer or the keyboard, has a
 * pause button (WCAG 2.2.2), and does not start for those who asked for less motion. Its colours are the theme's.
 */
export function Breaking({ list, env, t }: { list: CardData[]; env: NewsEnv; t: T }) {
  if (list.length === 0) return null;
  const many = list.length > 1;
  return (
    <section
      aria-label={t("breaking")}
      aria-roledescription={many ? "carousel" : undefined}
      data-breaking={many ? "" : undefined}
      className="breaking relative overflow-hidden bg-signal-breaking-bg text-signal-breaking-fg"
    >
      <div className="relative mx-auto flex max-w-7xl items-center gap-3 px-4 py-2.5 lg:gap-4 lg:py-3">
        <p className="flex shrink-0 items-center gap-2 self-start pt-0.5 font-bold text-caption text-signal-breaking-label uppercase tracking-wider lg:self-center">
          <span aria-hidden className="beat relative grid size-2.5 place-items-center">
            <span className="size-2.5 rounded-full bg-current" />
          </span>
          <Zap size={14} fill="currentColor" className="max-sm:hidden" />
          <span className="max-sm:sr-only">{t("breaking")}</span>
        </p>
        <ul className="grid min-w-0 flex-1" aria-live={many ? "off" : undefined}>
          {list.map((card, i) => (
            <li
              key={card.id}
              data-slide={i}
              data-on={i === 0 ? "" : undefined}
              aria-hidden={i > 0 ? "true" : undefined}
              inert={i > 0 ? true : undefined}
              aria-roledescription={many ? "slide" : undefined}
              aria-label={many ? t("breakingOf", { at: i + 1, total: list.length }) : undefined}
              className="slide relative col-start-1 row-start-1 flex min-w-0 flex-col justify-center"
            >
              <a
                href={card.path}
                className="line-clamp-2 font-semibold text-label after:absolute after:inset-0 hover:underline lg:line-clamp-1 lg:text-body-m"
              >
                {card.headline}
              </a>
              <span className="text-caption opacity-75">{ago(card.published_at, env)}</span>
            </li>
          ))}
        </ul>
        {many && (
          <div className="flex shrink-0 items-center gap-1">
            <span className="text-caption tabular-nums opacity-75" data-breaking-at aria-hidden>
              1/{list.length}
            </span>
            <button
              type="button"
              data-breaking-pause
              data-pause={t("breakingPause")}
              data-play={t("breakingPlay")}
              aria-label={t("breakingPause")}
              className="tap grid w-11 place-items-center rounded-full hover:bg-white/10"
            >
              <Pause size={16} className="when-playing" />
              <Play size={16} className="when-paused" />
            </button>
          </div>
        )}
      </div>
      {/* One sweep of light as it arrives (globals.css). */}
      <span aria-hidden className="breaking-shine pointer-events-none absolute inset-0" />
    </section>
  );
}
