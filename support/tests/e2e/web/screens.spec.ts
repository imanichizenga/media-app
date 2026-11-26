import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import type { Page } from "@playwright/test";
import { DESK, fresh, PHONE, places, ready, test } from "./helpers";

// The M2 gallery: SCREENS=m2 pnpm --filter @news/e2e web, then node contact-sheet.mjs m2.
// Every page on phone and desk, light and dark, Swahili and English. Home, article and category in the three
// themes. The app's own screens (from the M3.1 gallery) sit in the same rows, for support/docs/design/consistency.md.
const OUT = resolve(import.meta.dirname, "../../../docs/design/screens/m2");
const APP = resolve(import.meta.dirname, "../../../docs/design/screens/m3-1/s");
const SIZES = { phone: PHONE, desk: DESK };
const KEY = ["home", "article", "category"];
const THEMES = ["signature", "bold", "quiet"] as const;
// Web page → the app's screen of the same place.
const SAME: Record<string, string> = {
  home: "home",
  article: "article",
  category: "category",
  author: "author",
  video: "videos",
  shorts: "shorts",
  search: "explore",
  saved: "saved",
  profile: "you",
};

/** The stylesheet each theme would publish, made by the same code that publishes it. */
function css(theme: string): string {
  return execFileSync(
    "../../../backend/.venv/bin/python",
    [
      "../../../backend/manage.py",
      "shell",
      "-v0",
      "-c",
      `from newsplatform.site_config import brand; from newsplatform.site_config.schemas import Appearance; print(brand.css_of(Appearance(theme="${theme}"))[1], end="")`,
    ],
    { env: { ...process.env, DJANGO_SETTINGS_MODULE: "config.settings.dev" }, encoding: "utf8" },
  );
}

async function shoot(page: Page, file: string) {
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({ path: `${OUT}/${file}.jpg`, type: "jpeg", quality: 78, fullPage: false });
}

test.describe.configure({ mode: "serial" });
test.setTimeout(600_000);

test.beforeAll(() => {
  rmSync(OUT, { recursive: true, force: true });
  mkdirSync(OUT, { recursive: true });
  // The app beside the web: its after-shots, renamed into the same rows.
  if (!existsSync(APP)) return;
  for (const file of readdirSync(APP)) {
    const m = file.match(/^(ios|android)--(light|dark)--([a-z]+)\.jpg$/);
    if (!m) continue;
    const [, os, scheme, screen] = m;
    const web = Object.entries(SAME).find(([, app]) => app === screen)?.[0];
    if (web) copyFileSync(`${APP}/${file}`, `${OUT}/${web}--app-${os}--phone-${scheme}-sw.jpg`);
  }
});

for (const locale of ["sw", "en"] as const)
  for (const scheme of ["light", "dark"] as const)
    test(`every page: ${locale} ${scheme}`, async ({ browser }) => {
      const at = await places(locale);
      for (const [device, size] of Object.entries(SIZES)) {
        const context = await browser.newContext({
          viewport: size,
          colorScheme: scheme,
          locale: `${locale}-TZ`,
        });
        const page = await context.newPage();
        await fresh(page);
        for (const [name, path] of Object.entries(at)) {
          if (!path) continue;
          await ready(page, path);
          await shoot(page, `${name}--web--${device}-${scheme}-${locale}`);
          if (name === "home" || name === "article") {
            await page.evaluate(() => window.scrollTo(0, innerHeight * 1.5));
            await page.waitForTimeout(400);
            await shoot(page, `${name}--scrolled--${device}-${scheme}-${locale}`);
          }
        }
        await context.close();
      }
    });

test("the three themes on the key pages", async ({ browser }) => {
  const at = await places("sw");
  for (const theme of THEMES) {
    const body = css(theme);
    for (const [device, scheme] of [
      ["phone", "light"],
      ["desk", "dark"],
    ] as const) {
      const context = await browser.newContext({ viewport: SIZES[device], colorScheme: scheme });
      await context.route(/\/theme\/[0-9a-f]{16}\.css$/, (r) => r.fulfill({ body, contentType: "text/css" }));
      const page = await context.newPage();
      await fresh(page);
      for (const name of KEY) {
        await ready(page, at[name] as string);
        await shoot(page, `${theme}-${name}--web--${device}-${scheme}-sw`);
      }
      await context.close();
    }
  }
});

test("skeletons and states", async ({ browser }) => {
  const at = await places("sw");
  for (const [device, size] of Object.entries(SIZES)) {
    const context = await browser.newContext({ viewport: size });
    const page = await context.newPage();
    await fresh(page);
    await ready(page, "/skeletons");
    await shoot(page, `home--skeleton--${device}-light-sw`);
    await ready(page, at.missing as string);
    await shoot(page, `missing--404--${device}-light-sw`);
    await ready(page, "/");
    await context.setOffline(true);
    await page.locator("[data-offline]").waitFor();
    await shoot(page, `home--offline--${device}-light-sw`);
    await context.setOffline(false);
    await context.close();
  }
});
