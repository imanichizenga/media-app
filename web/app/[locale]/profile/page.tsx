import {
  ChevronRight,
  FileText,
  type Icon,
  Info,
  Languages,
  Mail,
  PenLine,
  Scale,
  Shield,
} from "@news/ui/icons";
import type { Metadata } from "next";
import type { ReactNode } from "react";
import { AccountCard } from "@/components/account";
import { SchemeChoice, TextSizeChoice } from "@/components/client";
import { Frame, Wide } from "@/components/frame";
import { PageHead } from "@/components/parts";
import { pages, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }> };
const SIGNS: Record<string, Icon> = {
  about: Info,
  "editorial-policy": PenLine,
  corrections: FileText,
  contact: Mail,
  privacy: Shield,
  terms: Scale,
};
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/profile"),
    title: words(locale)("navYou"),
    index: false,
  });
}
const Group = ({ title, children }: { title: string; children: ReactNode }) => (
  <section aria-label={title} className="flex flex-col gap-2">
    <h2 className="px-1 font-sans text-label text-text-secondary">{title}</h2>
    <div className="overflow-hidden rounded-lg border border-border bg-surface">{children}</div>
  </section>
);
const ROW = "flex min-h-13 items-center gap-3 px-4 hover:bg-surface-sunken";

/** The reader's account (or an invitation to one), and how the site behaves for them. */
export default async function Page({ params }: Props) {
  const { locale } = await params;
  const [site, foot] = await Promise.all([readSite(), pages(locale)]);
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  return (
    <Frame
      locale={locale}
      path={at(locale, "/profile")}
      place="you"
      view={viewOf(locale, site)}
      title={t("navYou")}
      other={at(other, "/profile")}
    >
      <Wide className="max-w-2xl!">
        <PageHead title={t("navYou")} hidden />
        <div className="flex flex-col gap-6 pt-4">
          <AccountCard t={t} brand={site.identity.brand_name} />
          <Group title={t("language")}>
            <ul className="divide-y divide-border">
              {(["sw", "en"] as const).map((l) => (
                <li key={l}>
                  <a
                    href={at(l, "/profile")}
                    hrefLang={l}
                    lang={l}
                    aria-current={l === locale ? "true" : undefined}
                    className={`${ROW} ${l === locale ? "font-semibold" : ""}`}
                  >
                    <Languages size={20} className="text-text-secondary" />
                    <span className="flex-1">{l === "sw" ? "Kiswahili" : "English"}</span>
                    {l === locale && <span aria-hidden>✓</span>}
                  </a>
                </li>
              ))}
            </ul>
          </Group>
          <Group title={t("appearance")}>
            <div className="p-2">
              <SchemeChoice
                legend={t("appearance")}
                names={[t("schemeSystem"), t("schemeLight"), t("schemeDark")]}
              />
            </div>
          </Group>
          <Group title={t("textSize")}>
            <div className="p-4">
              <TextSizeChoice label={t("textSize")} sample={t("textSizeSample")} />
            </div>
          </Group>
          {foot.results.length > 0 && (
            <Group title={t("aboutSection")}>
              <ul className="divide-y divide-border">
                {foot.results.map((p) => {
                  const Sign = SIGNS[p.key] ?? FileText;
                  return (
                    <li key={p.key}>
                      <a href={p.path} className={ROW}>
                        <Sign size={20} className="text-text-secondary" />
                        <span className="min-w-0 flex-1 truncate">{p.title}</span>
                        <ChevronRight size={18} className="text-text-secondary" />
                      </a>
                    </li>
                  );
                })}
              </ul>
            </Group>
          )}
        </div>
      </Wide>
    </Frame>
  );
}
