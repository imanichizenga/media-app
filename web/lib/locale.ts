export type Locale = "sw" | "en";
export const LOCALES: Locale[] = ["sw", "en"];
export const isLocale = (value: string): value is Locale => value === "sw" || value === "en";
/** The same addresses as the API's seo.paths and the app's links. */
export const at = (locale: Locale, path: string) =>
  locale === "sw" ? path : path === "/" ? "/en" : `/en${path}`;
/** What an address is outside its language: "/en/video" → "/video". */
export const bare = (path: string) => path.replace(/^\/en(?=\/|$)/, "") || "/";
export const PAGE_KEYS = ["about", "editorial-policy", "corrections", "contact", "privacy", "terms"] as const;
