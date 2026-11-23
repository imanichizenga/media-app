import type { Metadata, Viewport } from "next";
import { cookies, headers } from "next/headers";
import { NextIntlClientProvider } from "next-intl";
import { getLocale } from "next-intl/server";
import type { ReactNode } from "react";
import { Providers } from "@/components/providers";
import "./globals.css";

export const metadata: Metadata = { title: "Admin", robots: { index: false, follow: false } };
export const viewport: Viewport = { width: "device-width", initialScale: 1 };

export default async function RootLayout({ children }: { children: ReactNode }) {
  const [locale, jar, head] = await Promise.all([getLocale(), cookies(), headers()]);
  const theme = jar.get("theme")?.value;
  // The theme comes from a cookie, so no inline script is needed to avoid a flash.
  return (
    <html lang={locale} data-theme={theme === "dark" || theme === "light" ? theme : undefined}>
      <body>
        <NextIntlClientProvider>
          <Providers nonce={head.get("x-nonce") ?? ""}>{children}</Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
