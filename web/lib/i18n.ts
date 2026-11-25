import "server-only";
import en from "@news/i18n/en.json";
import sw from "@news/i18n/sw.json";
import { createTranslator } from "next-intl";
import type { Locale } from "./locale";

type Messages = typeof sw;
export type T = (key: keyof Messages, values?: Record<string, string | number>) => string;
const made: Partial<Record<Locale, T>> = {};
/** The same words as the app. On the server only: no catalogue is sent to the reader. */
export function words(locale: Locale): T {
  // biome-ignore lint/suspicious/noExplicitAny: the catalogue's own keys are the type
  made[locale] ??= createTranslator({ locale, messages: (locale === "en" ? en : sw) as any }) as unknown as T;
  return made[locale];
}
