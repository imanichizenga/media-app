import { Designed } from "@news/ui/news";
import type { Metadata } from "next";
import { SavedList } from "@/components/client";
import { Frame, Wide } from "@/components/frame";
import { BUTTON, PageHead } from "@/components/parts";
import { site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }> };
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/saved"),
    title: words(locale)("navSaved"),
    index: false,
  });
}
/** The same page for everyone: the list is the browser's own. */
export default async function Page({ params }: Props) {
  const { locale } = await params;
  const view = viewOf(locale, await readSite());
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  return (
    <Frame
      locale={locale}
      path={at(locale, "/saved")}
      place="saved"
      view={view}
      title={t("navSaved")}
      other={at(other, "/saved")}
    >
      <Wide className="max-w-3xl!">
        <PageHead title={t("navSaved")} hidden />
        <SavedList
          remove={t("unsave")}
          label={t("navSaved")}
          empty={
            <Designed
              kind="empty"
              title={t("savedEmptyTitle")}
              body={t("savedEmptyWeb")}
              action={
                <a href={at(locale, "/")} className={BUTTON}>
                  {t("savedEmptyAction")}
                </a>
              }
            />
          }
        />
      </Wide>
    </Frame>
  );
}
