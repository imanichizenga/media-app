import "server-only";
import { site } from "./api";
import { STYLE } from "./failure-style";
import { words } from "./i18n";
import { at, type Locale } from "./locale";
import { x } from "./xml";

/** When a page cannot be made: designed, in the reader's language, in the theme if it is known, and needing nothing. */
export async function failure(path: string): Promise<string> {
  const locale: Locale = path === "/en" || path.startsWith("/en/") ? "en" : "sw";
  const t = words(locale);
  const brand = await site().then(
    (s) => ({ name: s.identity.brand_name, css: s.theme.css }),
    () => null,
  );
  return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>${x(t("serverErrorTitle"))}</title>${brand ? `<link rel="stylesheet" href="${x(brand.css)}">` : ""}<style>${STYLE}</style></head><body><main id="main">${brand ? `<p>${x(brand.name)}</p>` : ""}<svg aria-hidden="true" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="22" y="30" width="76" height="60" rx="6"/><path d="M22 46h76M34 60h20M34 70h34M78 58l12 12M90 58 78 70"/></svg><h1>${x(t("serverErrorTitle"))}</h1><p>${x(t("errorBody"))}</p><a class="go" href="${x(path)}">${x(t("retry"))}</a><a href="${at(locale, "/")}">${x(t("goHome"))}</a></main></body></html>`;
}
