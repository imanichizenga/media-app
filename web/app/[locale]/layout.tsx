import type { Viewport } from "next";
import { headers } from "next/headers";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import { site as readSite } from "@/lib/api";
import { isLocale } from "@/lib/locale";
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
  const ios = /\/id(\d+)/.exec(site.apps.ios)?.[1];
  return (
    <html lang={locale} suppressHydrationWarning>
      <head>
        <script nonce={head.get("x-nonce") ?? undefined} suppressHydrationWarning>
          {EARLY}
        </script>
        {/* Content-hashed and immutable: the published theme, before first paint (ADR-0032). */}
        <link rel="stylesheet" href={site.theme.css} data-brand-theme="" />
        <link rel="manifest" href={`/theme/manifest-${locale}.webmanifest`} />
        {site.identity.symbol && <link rel="icon" href={site.identity.symbol.png["1x"]} />}
        {ios && <meta name="apple-itunes-app" content={`app-id=${ios}`} />}
      </head>
      <body>{children}</body>
    </html>
  );
}
