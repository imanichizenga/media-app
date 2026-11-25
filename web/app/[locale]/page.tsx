import type { Metadata } from "next";
import { HomeView } from "@/components/home";
import { home, site as readSite } from "@/lib/api";
import { at, type Locale } from "@/lib/locale";
import { metaOf } from "@/lib/meta";

type Props = { params: Promise<{ locale: Locale }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const other: Locale = locale === "sw" ? "en" : "sw";
  return metaOf({
    site: await readSite(),
    locale,
    path: at(locale, "/"),
    others: [{ locale: other, path: at(other, "/") }],
  });
}

export default async function Page({ params }: Props) {
  const { locale } = await params;
  return <HomeView locale={locale} h={await home(locale)} />;
}
