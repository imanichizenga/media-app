import type { Metadata } from "next";
import { Frame } from "@/components/frame";
import { Plans } from "@/components/paywall";
import { offer, site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";
import { viewOf } from "@/lib/view";

type Props = { params: Promise<{ locale: Locale }>; searchParams: Promise<{ next?: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/subscribe"),
    title: words(locale)("plansTitle"),
    index: false,
  });
}

/** Only this site's own pages are somewhere to come back to. */
const own = (next: string | undefined, locale: Locale) =>
  next && /^\/(?![/\\])[A-Za-z0-9/_.~%-]{0,300}$/.test(next) ? next : at(locale, "/");

/**
 * The plans (ADR-0052). The site's top and its bar stay, so a reader who would rather not pay goes on reading what
 * is free. The same page for everyone: who is signed in, and paying, is the island's (islands/subscribe.ts).
 */
export default async function Page({ params, searchParams }: Props) {
  const { locale } = await params;
  const { next } = await searchParams;
  const [site, plans] = await Promise.all([readSite(), offer(locale)]);
  const view = viewOf(locale, site);
  const t = words(locale);
  const other: Locale = locale === "sw" ? "en" : "sw";
  return (
    <Frame
      locale={locale}
      path={at(locale, "/subscribe")}
      place="you"
      view={view}
      title={t("plansTitle")}
      other={at(other, "/subscribe")}
    >
      <Plans offer={plans} t={t} locale={locale} next={own(next, locale)} />
    </Frame>
  );
}
