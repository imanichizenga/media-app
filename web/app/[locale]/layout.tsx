import type { Viewport } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { Offline } from "@/components/client";
import islands from "@/generated/islands.json";
import { site as readSite } from "@/lib/api";
import { words } from "@/lib/i18n";
import { at, isLocale } from "@/lib/locale";
import "../globals.css";

export async function generateViewport(): Promise<Viewport> {
  const { theme } = await readSite();
  return {
    width: "device-width",
    initialScale: 1,
    viewportFit: "cover",
    themeColor: [
      { media: "(prefers-color-scheme: light)", color: theme.theme_color.light },
      { media: "(prefers-color-scheme: dark)", color: theme.theme_color.dark },
    ],
  };
}

// Before first paint: the reader's own scheme and text size, so that nothing flashes.
const EARLY =
  "try{var d=document.documentElement,s=localStorage.scheme,t=localStorage.text;if(s==='dark'||s==='light')d.dataset.theme=s;if(/^[1-3]$/.test(t))d.dataset.text=t}catch(e){}";

export default async function Layout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  const [site, head] = await Promise.all([readSite(), headers()]);
  const t = words(locale);
  const nonce = head.get("x-nonce") ?? undefined;
  const ios = /\/id(\d+)/.exec(site.apps.ios)?.[1];
  return (
    <html lang={locale} suppressHydrationWarning>
      <head>
        <script nonce={nonce} data-keep="" suppressHydrationWarning>
          {EARLY}
        </script>
        <script type="module" src={islands.site} nonce={nonce} data-keep="" suppressHydrationWarning />
        {/* Content-hashed and immutable: the published theme, before first paint (ADR-0032). */}
        <link rel="stylesheet" href={site.theme.css} data-brand-theme="" />
        <link rel="manifest" href={`/theme/manifest-${locale}.webmanifest`} />
        {site.identity.symbol && <link rel="icon" href={site.identity.symbol.png["1x"]} />}
        {ios && <meta name="apple-itunes-app" content={`app-id=${ios}`} />}
      </head>
      <body>
        <div id="page">{children}</div>
        <Offline text={t("offlineNote")} action={t("offlineAction")} href={at(locale, "/saved")} />
        <p
          id="toast"
          role="status"
          hidden
          className="fixed bottom-24 left-1/2 z-40 -translate-x-1/2 rounded-full bg-text-primary px-4 py-2 text-bg text-label [[hidden]]:hidden"
        />
        <p id="say" role="status" className="sr-only" />
      </body>
    </html>
  );
}
