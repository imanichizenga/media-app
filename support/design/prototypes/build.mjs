// Writes dist/<locale>/<theme>/<scheme>/<page>.html: plain files, no script. Open them, or `node shoot.mjs` for the gallery.
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { DEFAULT, derive, SCHEMES, stylesheet, THEMES } from "@news/design-tokens/theme";
import tailwind from "@tailwindcss/postcss";
import postcss from "postcss";
import { createServer } from "vite";

const root = new URL(".", import.meta.url).pathname;
const dist = `${root}dist`;
rmSync(dist, { recursive: true, force: true });
mkdirSync(`${dist}/fonts`, { recursive: true });
cpSync(`${root}../../packages/screens/media`, `${dist}/media`, { recursive: true });
for (const font of ["inter", "newsreader"])
  cpSync(
    `${root}node_modules/@fontsource-variable/${font}/files/${font}-latin-wght-normal.woff2`,
    `${dist}/fonts/${font}.woff2`,
  );
const from = `${root}src/styles.css`;
const css = await postcss([tailwind()]).process(readFileSync(from, "utf8"), { from });
writeFileSync(`${dist}/styles.css`, css.css);
for (const theme of THEMES)
  writeFileSync(
    `${dist}/theme-${theme}.css`,
    stylesheet(derive(theme, "light", DEFAULT.color), derive(theme, "dark", DEFAULT.color)),
  );

const vite = await createServer({
  root,
  server: { middlewareMode: true },
  appType: "custom",
  logLevel: "error",
});
const { pages, html } = await vite.ssrLoadModule("/src/html.tsx");
let count = 0;
for (const locale of ["sw", "en"])
  for (const theme of THEMES)
    for (const scheme of SCHEMES)
      for (const name of Object.keys(pages)) {
        const dir = `${dist}/${locale}/${theme}/${scheme}`;
        mkdirSync(dir, { recursive: true });
        writeFileSync(`${dir}/${name}.html`, html(name, locale, theme, scheme));
        count++;
      }
await vite.close();
console.log(`${count} pages`);
