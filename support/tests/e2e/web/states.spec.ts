import type { Page } from "@playwright/test";
import { DESK, expect, PHONE, places, ready, test } from "./helpers";

const TOLERANCE = 8;
/** Where the parts that both a skeleton and its page have stand. */
const PARTS: Record<string, string[]> = {
  article: ["article header p:first-child", "article h1"],
  video: ['[data-card="lead"]', '[data-card="video"]'],
  category: ['[data-card="lead"]', '[data-card="row"], [data-card="story"]'],
  latest: ['[data-card="lead"]'],
  search: ['[data-page="explore"] li'],
  cluster: ["h1", '[data-card="lead"]'],
  tag: ["h1"],
  author: ["main [data-face]"],
  page: ["h1"],
  shorts: ["[data-bar]"],
  home: ["header", "main"],
};
const rect = (page: Page, selector: string) =>
  page.evaluate((s) => {
    const el = [...document.querySelectorAll(s)].find((e) => e.getBoundingClientRect().height > 0);
    const r = el?.getBoundingClientRect();
    return r ? { top: r.top, left: r.left, width: r.width } : null;
  }, selector);

for (const size of [PHONE, DESK])
  test(`each skeleton holds the place of its page, ${size.width}`, async ({ page }) => {
    test.setTimeout(240_000);
    await page.setViewportSize(size);
    const all = await places("sw");
    for (const [name, parts] of Object.entries(PARTS)) {
      const path = all[name];
      if (!path) continue;
      // From another page of the site, on a slow line.
      await ready(page, name === "home" ? "/latest" : "/");
      await page.waitForTimeout(400);
      let release = () => {};
      const held = new Promise<void>((r) => {
        release = r;
      });
      const url = `http://localhost:3000${path}`;
      await page.route(url, async (route) => {
        await held;
        await route.continue();
      });
      await page.evaluate(
        ([p, h]) => {
          const card = document.createElement("div");
          card.dataset.card = "test";
          card.innerHTML = `<h3><a href="${p}"></a></h3>`;
          const a = card.querySelector("a") as HTMLAnchorElement;
          a.textContent = h ?? "";
          document.getElementById("main")?.append(card);
          a.click();
        },
        [path, name === "article" ? await headlineOf(path) : ""],
      );
      await expect(page.locator("#page .bone, #page .animate-pulse").first(), name).toBeAttached();
      const before = await Promise.all(parts.map((p) => rect(page, p)));
      release();
      await expect(page.locator("#page[data-loading]")).toHaveCount(0);
      await page.unroute(url);
      for (const [i, part] of parts.entries()) {
        const [was, is] = [before[i], await rect(page, part)];
        expect(was, `${name} skeleton has ${part}`).not.toBeNull();
        expect(is, `${name} has ${part}`).not.toBeNull();
        for (const side of ["top", "left", "width"] as const)
          expect(
            Math.abs((was?.[side] ?? 0) - (is?.[side] ?? 0)),
            `${name} ${part} ${side}`,
          ).toBeLessThanOrEqual(TOLERANCE);
      }
    }
  });
const headlineOf = async (path: string) => {
  const html = await (await fetch(`http://localhost:3000${path}`)).text();
  return /<h1[^>]*>([^<]+)<\/h1>/.exec(html)?.[1] ?? "";
};

test("nothing moves while a page arrives (CLS)", async ({ page }) => {
  await page.addInitScript(() => {
    (window as unknown as Record<string, number>).cls = 0;
    new PerformanceObserver((l) => {
      for (const e of l.getEntries() as (PerformanceEntry & { value: number; hadRecentInput: boolean })[])
        if (!e.hadRecentInput) (window as unknown as Record<string, number>).cls += e.value;
    }).observe({ type: "layout-shift", buffered: true });
  });
  for (const size of [PHONE, DESK]) {
    await page.setViewportSize(size);
    for (const [name, path] of Object.entries(await places("sw"))) {
      if (!path) continue;
      await ready(page, path);
      await page.waitForTimeout(150);
      const cls = await page.evaluate(() => (window as unknown as Record<string, number>).cls);
      expect(cls, `${name} ${size.width}`).toBeLessThan(0.05);
    }
  }
});

test("no live coverage and no breaking news: absent, never empty", async ({ page }) => {
  await page.setViewportSize(PHONE);
  await page.goto("/search");
  expect(await page.locator("main .signal-breaking-bg").count()).toBe(0);
  await page.goto("/saved");
  await expect(page.locator("[data-empty]")).toBeVisible();
  expect(
    await page
      .locator("ul:empty")
      .evaluateAll((l) => l.filter((e) => e.getBoundingClientRect().height > 0).length),
  ).toBe(0);
});

test("a page that is not here says so, in its language, as a 404", async ({ page }) => {
  for (const [path, words] of [
    ["/hakuna/ukurasa", "Habari hii haipo"],
    ["/en/no/such", "This story is not here"],
    ["/a/b/c/d", "Habari hii haipo"],
    ["/latest?cursor=<x>", "Habari hii haipo"],
  ] as const) {
    const res = await page.goto(path);
    expect(res?.status(), path).toBe(404);
    await expect(page.locator("h1")).toHaveText(words);
    await expect(page.locator("main a").first()).toBeVisible();
  }
});

test("a first-ever visitor on a bad line: inside navigation falls back to the browser", async ({ page }) => {
  const { article } = await places("sw");
  await ready(page, "/");
  await page.route(`http://localhost:3000${article}`, (route) =>
    route.request().isNavigationRequest() ? route.continue() : route.abort(),
  );
  await page.evaluate((p) => {
    const a = document.createElement("a");
    a.href = p ?? "";
    a.textContent = "x";
    document.getElementById("main")?.append(a);
    a.click();
  }, article);
  await expect(page.locator("article h1")).toBeVisible();
});
