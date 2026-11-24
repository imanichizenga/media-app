import { pageOf, pages } from "@news/screens";
import { renderToStaticMarkup } from "react-dom/server";

export { pages };
export function html(name: string, locale: "sw" | "en", theme: string, scheme: "light" | "dark") {
  const page = pages[name];
  if (!page) throw new Error(name);
  return `<!doctype html>${renderToStaticMarkup(
    <html lang={locale} data-theme={scheme}>
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <title>{`${name} · prototype`}</title>
        <link rel="stylesheet" href="../../../styles.css" />
        <link rel="stylesheet" href={`../../../theme-${theme}.css`} />
      </head>
      <body>{page(pageOf(locale, "../../.."))}</body>
    </html>,
  )}`;
}
