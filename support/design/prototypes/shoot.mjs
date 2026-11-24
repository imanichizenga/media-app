// After `pnpm --filter @news/prototypes build`: support/docs/design/screens/m2-themes. Red Signature in every combination of
// device, scheme and language; the key screens in the other two themes; the app's wide windows at 768 and 1024.
// Run with: pnpm --filter @news/e2e exec node ../../design/prototypes/shoot.mjs [name prefix]
import { mkdirSync, readdirSync, rmSync } from "node:fs";
import { createRequire } from "node:module";

const root = new URL(".", import.meta.url).pathname;
const require = createRequire(`${root}../../tests/e2e/package.json`);
const { chromium } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const OUT = `${root}../../docs/design/screens/m2-themes`;
const only = process.argv[2];
if (!only) rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });
const SIZES = {
  desktop: { width: 1280, height: 900 },
  phone: { width: 390, height: 844 },
  tablet768: { width: 768, height: 1024 },
  tablet1024: { width: 1024, height: 1366 },
};
const KEY = new Set(["home", "article", "shorts", "comments", "auth", "breaking", "onboarding-1-welcome"]);
// Long pages are shown whole; what is fixed to the window is shown as a window.
const WHOLE = /^(home|article|category|video|live|search)/;
const jobs = [];
for (const theme of ["signature", "bold", "quiet"])
  for (const scheme of ["light", "dark"])
    for (const locale of ["sw", "en"]) {
      const dir = `${root}dist/${locale}/${theme}/${scheme}`;
      for (const file of readdirSync(dir).sort()) {
        const name = file.replace(".html", "");
        if (only && !name.startsWith(only)) continue;
        if (theme !== "signature" && !KEY.has(name)) continue;
        const devices = name.startsWith("tablet")
          ? ["tablet768", "tablet1024"]
          : name.startsWith("onboarding") // the app only
            ? ["phone"]
            : ["phone", "desktop"];
        for (const device of devices)
          jobs.push({ theme, scheme, locale, name, device, url: `file://${dir}/${file}` });
      }
    }
const browser = await chromium.launch();
let wide = 0;
const faults = new Set();
async function shoot({ theme, scheme, locale, name, device, url }) {
  const context = await browser.newContext({ viewport: SIZES[device], reducedMotion: "reduce" });
  const page = await context.newPage();
  await page.goto(url);
  await page.evaluate(() => {
    for (const i of document.images) i.loading = "eager";
    return Promise.all([
      document.fonts.ready,
      ...[...document.images].map((i) => i.decode().catch(() => {})),
    ]);
  });
  const over = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
  if (over > 0) {
    wide++;
    console.log(`SIDEWAYS ${theme} ${name} ${device} by ${over}`);
  }
  const { violations } = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
    .analyze();
  for (const v of violations)
    for (const n of v.nodes) faults.add(`${v.id} ${theme} ${scheme} ${name} ${n.html.slice(0, 110)}`);
  const [screen, state] = name.endsWith("-skeleton") ? [name.slice(0, -9), "skeleton"] : [name, "loaded"];
  if (WHOLE.test(name)) {
    const height = Math.min(await page.evaluate(() => document.documentElement.scrollHeight), 2600);
    await page.setViewportSize({ ...SIZES[device], height: Math.max(height, SIZES[device].height) });
  }
  await page.screenshot({
    path: `${OUT}/${theme}-${screen}--${state}--${device}-${scheme}-${locale}.jpg`,
    type: "jpeg",
    quality: 68,
  });
  await context.close();
}
let next = 0;
await Promise.all(
  Array.from({ length: 4 }, async () => {
    while (next < jobs.length) await shoot(jobs[next++]);
  }),
);
await browser.close();
for (const f of faults) console.log(`AXE ${f}`);
console.log(`${jobs.length} screens, ${faults.size} axe findings, ${wide} scroll sideways`);
process.exitCode = faults.size || wide ? 1 : 0;
