import { Designed } from "@news/ui/news";
import type { Metadata } from "next";
import { Frame } from "@/components/frame";
import { BUTTON } from "@/components/parts";
import { site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { viewOf } from "@/lib/view";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: Locale }>;
}): Promise<Metadata> {
  return {
    title: words((await params).locale)("notFoundTitle"),
    robots: { index: false, follow: true },
    // Read by lib/slim.ts: this page is never a 200.
    other: { "x-status": "404" },
  };
}
/** Not here, in the reader's language, with the way back. */
export default async function Page({ params }: { params: Promise<{ locale: Locale }> }) {
  const { locale } = await params;
  const t = words(locale);
  return (
    <Frame locale={locale} path="" view={viewOf(locale, await readSite())} title={t("notFoundTitle")}>
      <Designed
        kind="empty"
        level={1}
        title={t("notFoundTitle")}
        body={t("notFoundBody")}
        action={
          <div className="flex flex-wrap justify-center gap-3">
            <a href={at(locale, "/")} className={BUTTON}>
              {t("goHome")}
            </a>
            <a
              href={at(locale, "/search")}
              className="tap inline-flex items-center px-4 text-label underline"
            >
              {t("navExplore")}
            </a>
          </div>
        }
      />
    </Frame>
  );
}
