import { cx } from "@news/ui/base";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";

/** Two light words (N7): weight and a line for the open one. */
export function VideoTabs({
  locale,
  open,
  onDark = false,
}: {
  locale: Locale;
  open: "shorts" | "video";
  onDark?: boolean;
}) {
  const t = words(locale);
  return (
    <nav aria-label={t("videos")}>
      <ul className="flex justify-center gap-2">
        {(["shorts", "video"] as const).map((key) => (
          <li key={key}>
            <a
              href={at(locale, `/${key}`)}
              aria-current={key === open ? "page" : undefined}
              className={cx(
                "inline-flex h-12 items-center border-b-2 px-4 text-label",
                key === open
                  ? cx(
                      "font-semibold",
                      onDark ? "border-white text-white" : "border-brand-text text-text-primary",
                    )
                  : cx("border-transparent", onDark ? "text-white/80" : "text-text-secondary"),
              )}
            >
              {t(key === "shorts" ? "shorts" : "longVideos")}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
