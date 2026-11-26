import en from "@news/i18n/en.json" with { type: "json" };
import sw from "@news/i18n/sw.json" with { type: "json" };
import { STYLE } from "./failure-style";
import { at, type Locale } from "./locale";
import { x } from "./xml";

/** The failure page itself, from what is known: pure, so the gallery draws the very page readers get. */
export function failurePage(path: string, brand: { name: string; css: string } | null): string {
  const locale: Locale = path === "/en" || path.startsWith("/en/") ? "en" : "sw";
  // Four plain words, read directly: this page must render with nothing else working (and in the gallery's Node).
  const t = (key: "serverErrorTitle" | "errorBody" | "retry" | "goHome") => (locale === "en" ? en : sw)[key];
  return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>${x(t("serverErrorTitle"))}</title>${brand ? `<link rel="stylesheet" href="${x(brand.css)}">` : ""}<style>${STYLE}</style></head><body><main id="main">${brand ? `<p>${x(brand.name)}</p>` : ""}<svg aria-hidden="true" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="22" y="30" width="76" height="60" rx="6"/><path d="M22 46h76M34 60h20M34 70h34M78 58l12 12M90 58 78 70"/></svg><h1>${x(t("serverErrorTitle"))}</h1><p>${x(t("errorBody"))}</p><a class="go" href="${x(path)}">${x(t("retry"))}</a><a href="${at(locale, "/")}">${x(t("goHome"))}</a></main></body></html>`;
}
