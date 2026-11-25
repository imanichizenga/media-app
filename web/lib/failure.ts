import "server-only";
import { site } from "./api";
import { words } from "./i18n";
import { at, type Locale } from "./locale";
import { x } from "./xml";

/** When a page cannot be made: designed, in the reader's language, in the theme if it is known, and needing nothing. */
export async function failure(path: string, nonce: string): Promise<string> {
  const locale: Locale = path === "/en" || path.startsWith("/en/") ? "en" : "sw";
  const t = words(locale);
  const brand = await site().then(
    (s) => ({ name: s.identity.brand_name, css: s.theme.css }),
    () => null,
  );
  return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>${x(t("serverErrorTitle"))}</title>${brand ? `<link rel="stylesheet" href="${x(brand.css)}">` : ""}<style nonce="${nonce}">
:root{color-scheme:light dark}
body{margin:0;min-height:100dvh;display:grid;place-items:center;padding:16px;text-align:center;font:17px/1.6 system-ui,sans-serif;background:var(--color-bg,Canvas);color:var(--color-text-primary,CanvasText)}
svg{width:128px;height:128px}h1{font:600 26px/1.25 Georgia,serif;margin:16px 0 8px}p{margin:0 auto 24px;max-width:24rem}
a{display:inline-flex;align-items:center;min-height:44px;padding:0 20px;margin:4px;border-radius:8px;color:inherit}
a.go{background:var(--color-brand,#b5121b);color:var(--color-on-brand,#fff);text-decoration:none}
</style></head><body><main id="main">${brand ? `<p>${x(brand.name)}</p>` : ""}<svg aria-hidden="true" viewBox="0 0 120 120" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><rect x="22" y="30" width="76" height="60" rx="6"/><path d="M22 46h76M34 60h20M34 70h34M78 58l12 12M90 58 78 70"/></svg><h1>${x(t("serverErrorTitle"))}</h1><p>${x(t("errorBody"))}</p><a class="go" href="${x(path)}">${x(t("retry"))}</a><a href="${at(locale, "/")}">${x(t("goHome"))}</a></main></body></html>`;
}
