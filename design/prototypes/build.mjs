// Writes dist/<locale>/<theme>/<page>.html: plain files, no script. Open them, or `node shoot.mjs` for the gallery.
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import tailwind from "@tailwindcss/postcss";
import postcss from "postcss";
import { createServer } from "vite";

const root = new URL(".", import.meta.url).pathname;
const dist = `${root}dist`;
rmSync(dist, { recursive: true, force: true });
mkdirSync(`${dist}/fonts`, { recursive: true });
cpSync(`${root}public`, dist, { recursive: true });
for (const font of ["inter", "newsreader"])
  cpSync(
    `${root}node_modules/@fontsource-variable/${font}/files/${font}-latin-wght-normal.woff2`,
    `${dist}/fonts/${font}.woff2`,
  );
const from = `${root}src/styles.css`;
const css = await postcss([tailwind()]).process(readFileSync(from, "utf8"), { from });
writeFileSync(`${dist}/styles.css`, css.css);

const vite = await createServer({
  root,
  server: { middlewareMode: true },
  appType: "custom",
  logLevel: "error",
});
const { pages, html } = await vite.ssrLoadModule("/src/index.tsx");
let count = 0;
for (const locale of ["sw", "en"])
  for (const theme of ["light", "dark"])
    for (const name of Object.keys(pages)) {
      mkdirSync(`${dist}/${locale}/${theme}`, { recursive: true });
      writeFileSync(`${dist}/${locale}/${theme}/${name}.html`, html(name, locale, theme));
      count++;
    }
await vite.close();
console.log(`${count} pages`);
