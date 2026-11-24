// After `pnpm --filter @news/prototypes build`: docs/design/screens/m2-design, in four combinations that cover each
// pair of device, theme and language. Run with: pnpm --filter @news/e2e exec node ../../design/prototypes/shoot.mjs
import { mkdirSync, readdirSync, rmSync } from "node:fs";
import { createRequire } from "node:module";

const root = new URL(".", import.meta.url).pathname;
const require = createRequire(`${root}../../tests/e2e/package.json`);
const { chromium } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const OUT = `${root}../../docs/design/screens/m2-design`;
rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });
const VARIANTS = [
  ["desktop", "light", "en"],
  ["desktop", "dark", "sw"],
  ["phone", "light", "sw"],
  ["phone", "dark", "en"],
];
const SIZES = { desktop: { width: 1280, height: 900 }, phone: { width: 390, height: 844 } };
// Long pages are shown whole; what is fixed to the window is shown as a window.
const WHOLE = /^(home|article|category|video|live|search)/;
const only = process.argv[2];
const browser = await chromium.launch();
let wide = 0;
const faults = new Set();
for (const [device, theme, locale] of VARIANTS) {
  const page = await (
    await browser.newContext({ viewport: SIZES[device], reducedMotion: "reduce" })
  ).newPage();
  const dir = `${root}dist/${locale}/${theme}`;
  for (const file of readdirSync(dir).sort()) {
    const name = file.replace(".html", "");
    if (only && !name.startsWith(only)) continue;
    if (device === "desktop" && name.startsWith("onboarding")) continue; // the app only
    await page.goto(`file://${dir}/${file}`);
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
      console.log(`SIDEWAYS ${name} ${device} by ${over}`);
    }
    const { violations } = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
      .analyze();
    for (const v of violations)
      for (const n of v.nodes) faults.add(`${v.id} ${name} ${theme} ${n.html.slice(0, 110)}`);
    const [screen, state] = name.endsWith("-skeleton") ? [name.slice(0, -9), "skeleton"] : [name, "loaded"];
    const full = WHOLE.test(name);
    const height = full
      ? Math.min(await page.evaluate(() => document.documentElement.scrollHeight), 2600)
      : 0;
    if (full)
      await page.setViewportSize({ ...SIZES[device], height: Math.max(height, SIZES[device].height) });
    await page.screenshot({
      path: `${OUT}/${screen}--${state}--${device}-${theme}-${locale}.jpg`,
      type: "jpeg",
      quality: 72,
    });
    await page.setViewportSize(SIZES[device]);
  }
}
await browser.close();
for (const f of faults) console.log(`AXE ${f}`);
console.log(wide ? `${wide} pages scroll sideways` : "no page scrolls sideways");
