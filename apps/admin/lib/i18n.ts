import { cookies } from "next/headers";
import { getRequestConfig } from "next-intl/server";

export const LOCALES = ["sw", "en"] as const;
export type Locale = (typeof LOCALES)[number];

export default getRequestConfig(async () => {
  const locale: Locale = (await cookies()).get("locale")?.value === "en" ? "en" : "sw";
  return {
    locale,
    timeZone: "Africa/Dar_es_Salaam",
    messages: (await import(`../messages/${locale}.json`)).default,
  };
});
