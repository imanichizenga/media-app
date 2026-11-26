// One public catalogue → ARB for the app (gen-l10n) and JSON for the website (next-intl). [Swahili, English].
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";

const root = new URL(".", import.meta.url).pathname;
const all = JSON.parse(readFileSync(`${root}public.json`, "utf8"));
const NUMBER = new Set(["n", "i"]);
const KNOWN = ["n", "i", "when", "at", "total", "name", "v"];
const names = (text) => KNOWN.filter((x) => new RegExp(`\\{${x}[,}]`).test(text));
mkdirSync(`${root}web`, { recursive: true });
mkdirSync(`${root}../../../mobile/lib/l10n`, { recursive: true });
for (const [i, locale] of ["sw", "en"].entries()) {
  const arb = { "@@locale": locale };
  const web = {};
  for (const [key, pair] of Object.entries(all)) {
    arb[key] = pair[i];
    web[key] = pair[i];
    const used = names(all[key][0]);
    if (used.join() !== names(all[key][1]).join())
      throw new Error(`${key}: the two languages differ in ${used}`);
    if (locale === "sw" && used.length)
      arb[`@${key}`] = {
        placeholders: Object.fromEntries(used.map((n) => [n, { type: NUMBER.has(n) ? "int" : "String" }])),
      };
  }
  writeFileSync(`${root}../../../mobile/lib/l10n/app_${locale}.arb`, `${JSON.stringify(arb, null, 2)}\n`);
  writeFileSync(`${root}web/${locale}.json`, `${JSON.stringify(web, null, 2)}\n`);
}
console.log(`${Object.keys(all).length} strings`);
