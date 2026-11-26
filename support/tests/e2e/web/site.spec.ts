import { AxeBuilder } from "@axe-core/playwright";
import { api, DESK, expect, PHONE, places, ready, SMALL, test } from "./helpers";

test.describe("guest browsing", () => {
  test("from Home to a story, to its section, and back to the same place", async ({ page }) => {
    await page.setViewportSize(PHONE);
    await ready(page, "/");
    let documents = 0;
    page.on("request", (r) => r.isNavigationRequest() && documents++);
    await page.evaluate(() => scrollTo(0, 400));
    const card = page.locator('[data-card="row"] a').nth(1);
    // biome-ignore lint/performance/useDomNodeTextContent: Playwright's Locator.innerText, the text a reader sees
    const headline = await card.innerText();
    await card.click();
    await expect(page.locator("article h1")).toHaveText(headline);
    await expect(page).toHaveTitle(new RegExp(headline.slice(0, 20)));
    await page.locator("article header a").first().click();
    await expect(page.locator("main h1")).toBeAttached();
    await page.goBack();
    await expect(page.locator("article h1")).toHaveText(headline);
    await page.goBack();
    await expect(page.locator('[data-card="lead"]').first()).toBeVisible();
    expect(Math.abs((await page.evaluate(() => scrollY)) - 400)).toBeLessThan(60);
    expect(documents).toBe(0); // never left the site
  });

  test("every page can be read without script", async ({ browser }) => {
    const all = await places("sw");
    const page = await (await browser.newContext({ javaScriptEnabled: false })).newPage();
    for (const [name, path] of Object.entries(all)) {
      if (!path) continue;
      const res = await page.goto(path);
      expect(res?.status(), name).toBe(name === "missing" ? 404 : 200);
      await expect(page.locator("h1").first(), name).toBeAttached();
      if (name !== "saved") expect(await page.locator("main .bone").count(), name).toBe(0);
    }
  });

  test("the other language, the same story", async ({ page }) => {
    const { article } = await places("sw");
    await page.setViewportSize(DESK);
    await page.goto(article ?? "");
    await page.locator('header a[hreflang="en"]').click();
    await expect(page.locator("html")).toHaveAttribute("lang", "en");
    await expect(page.locator("article h1")).toBeVisible();
    await expect(page).toHaveURL(/\/en\//);
  });

  test("saved on this device, and forgotten again", async ({ page }) => {
    const { article } = await places("sw");
    await page.setViewportSize(PHONE);
    await ready(page, article ?? "");
    // biome-ignore lint/performance/useDomNodeTextContent: Playwright's Locator.innerText, the text a reader sees
    const headline = await page.locator("article h1").innerText();
    await page.locator('[data-bar] [data-do="save"]').click();
    await expect(page.locator('[data-bar] [data-do="save"]')).toHaveAttribute("aria-pressed", "true");
    await page.goto("/saved");
    await expect(page.locator("[data-saved] li")).toContainText(headline);
    await page.locator('[data-do="unsave"]').click();
    await expect(page.locator("[data-empty]")).toBeVisible();
  });

  test("a link is shared", async ({ page, context }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await page.addInitScript(() => Object.defineProperty(navigator, "share", { value: undefined }));
    const { article } = await places("sw");
    await page.setViewportSize(PHONE);
    await ready(page, article ?? "");
    await page.locator('[data-bar] [data-do="share"]').click();
    await expect(page.locator("#toast")).toBeVisible();
    expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(`http://localhost:3000${article}`);
  });

  test("text size and scheme are kept, and nothing flashes", async ({ page }) => {
    await ready(page, "/profile");
    await page.locator('[data-schemes] input[value="dark"]').check({ force: true });
    await page.locator("[data-text-range]").fill("2");
    // Before anything is drawn on the next page, the choice is already on it.
    await page.addInitScript(() => {
      new MutationObserver((_, o) => {
        if (!document.body) return;
        (window as unknown as Record<string, unknown>).first = [
          document.documentElement.dataset.theme,
          document.documentElement.dataset.text,
          getComputedStyle(document.documentElement).getPropertyValue("--color-bg"),
        ];
        o.disconnect();
      }).observe(document, { childList: true, subtree: true });
    });
    await page.goto("/");
    const [theme, text, bg] =
      (await page.evaluate(() => (window as unknown as Record<string, string[]>).first)) ?? [];
    expect([theme, text]).toEqual(["dark", "2"]);
    expect(bg?.trim()).not.toBe("#ffffff");
    await page.emulateMedia({ colorScheme: "light" });
    const dark = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    expect(dark).not.toBe("rgb(255, 255, 255)");
  });

  test("shorts: one plays, the next when it is reached", async ({ page }) => {
    await page.setViewportSize(PHONE);
    await page.goto("/shorts");
    const playing = () => page.evaluate(() => [...document.querySelectorAll("video")].map((v) => !v.paused));
    await expect.poll(async () => (await playing())[0], { timeout: 20_000 }).toBe(true);
    await page.locator("[data-shorts]").evaluate((el) => el.scrollTo(0, el.clientHeight));
    await expect
      .poll(async () => (await playing()).slice(0, 2).join(), { timeout: 20_000 })
      .toBe("false,true");
    await page.locator('[data-do="mute"]').nth(1).click();
    expect(await page.evaluate(() => document.querySelectorAll("video")[1]?.muted)).toBe(false);
  });

  test("a video plays when asked, and not before", async ({ page }) => {
    const { "video-story": path } = await places("sw");
    const asked: string[] = [];
    page.on("request", (r) => /\.m3u8|hls/.test(r.url()) && asked.push(r.url()));
    await ready(page, path ?? "");
    expect(asked).toEqual([]);
    await page.locator('[data-do="video"]').first().click();
    await expect
      .poll(() => page.evaluate(() => (document.querySelector("video")?.currentTime ?? 0) > 0), {
        timeout: 20_000,
      })
      .toBe(true);
  });

  test("offline: said, with the way to what was saved", async ({ page, context }) => {
    await ready(page, "/");
    await context.setOffline(true);
    await expect(page.locator("[data-offline]")).toBeVisible();
    await context.setOffline(false);
    await expect(page.locator("[data-offline]")).toBeHidden();
  });
});

test.describe("space is for news", () => {
  for (const path of ["/", "/en"])
    for (const size of [SMALL, PHONE])
      test(`the lead's whole headline and meta line stand above the bar: ${path} at ${size.width}`, async ({
        page,
      }) => {
        await page.setViewportSize(size);
        await page.goto(path);
        const rects = await page.evaluate(() => {
          const box = (s: string) => document.querySelector(s)?.getBoundingClientRect();
          return {
            bar: box("[data-bar]")?.top ?? 0,
            headline: box('[data-card="lead"] h2')?.bottom ?? 1e9,
            meta: box('[data-card="lead"] p')?.bottom ?? 1e9,
            next: box('[data-card="row"]')?.top ?? 1e9,
            clamp: (() => {
              const h = document.querySelector('[data-card="lead"] h2');
              return h ? h.scrollHeight - h.clientHeight : 0;
            })(),
          };
        });
        expect(rects.headline).toBeLessThanOrEqual(rects.bar);
        expect(rects.meta).toBeLessThanOrEqual(rects.bar);
        expect(rects.clamp).toBeLessThanOrEqual(2);
        if (size === PHONE) expect(rects.next).toBeLessThan(rects.bar - 40);
      });

  test("an article's headline, standfirst and byline are in the first view; its picture is 40% at most", async ({
    page,
  }) => {
    const { article } = await places("sw");
    await page.setViewportSize(PHONE);
    await page.goto(article ?? "");
    const bar = await page.locator("[data-bar]").evaluate((e) => e.getBoundingClientRect().top);
    const header = await page.locator("article header").evaluate((e) => e.getBoundingClientRect().bottom);
    expect(header).toBeLessThanOrEqual(bar);
    const hero = await page
      .locator(".hero")
      .first()
      .evaluate((e) => e.getBoundingClientRect());
    expect(hero.height).toBeLessThanOrEqual(0.4 * PHONE.height + 1);
    expect(hero.height).toBeLessThanOrEqual((hero.width * 9) / 16 + 1);
  });

  test("the bar covers nothing: at the end of every story the last words are above it", async ({ page }) => {
    const all = await places("sw");
    await page.setViewportSize(PHONE);
    for (const path of [all.article, all.live, all["video-story"], all.page]) {
      if (!path) continue;
      await page.goto(path);
      const gap = await page.evaluate(() => {
        scrollTo(0, document.documentElement.scrollHeight);
        const bar = document.querySelector("[data-bar]")?.getBoundingClientRect().top ?? 0;
        const last =
          [...document.querySelectorAll("main p, main h3, footer a")].at(-1)?.getBoundingClientRect()
            .bottom ?? 0;
        return bar - last;
      });
      expect(gap, path).toBeGreaterThanOrEqual(0);
    }
  });

  test("the bar steps aside while reading down, and returns", async ({ page }) => {
    const { article } = await places("sw");
    await page.setViewportSize(SMALL);
    await ready(page, article ?? "");
    for (let i = 0; i < 4; i++) await page.mouse.wheel(0, 120);
    await expect(page.locator("html")).toHaveAttribute("data-reading", "");
    await page.mouse.wheel(0, -120);
    await expect(page.locator("html")).not.toHaveAttribute("data-reading", "");
  });

  for (const locale of ["sw", "en"] as const)
    test(`meta is one line and nothing scrolls sideways, 320 to 1440: ${locale}`, async ({ page }) => {
      const all = await places(locale);
      for (const width of [320, 390, 768, 1024, 1440]) {
        await page.setViewportSize({ width, height: 800 });
        for (const [name, path] of Object.entries(all)) {
          if (!path) continue;
          await page.goto(path);
          const found = await page.evaluate(() => ({
            wide: document.documentElement.scrollWidth - innerWidth,
            tall: [...document.querySelectorAll("[data-card] p:has(> time)")].filter(
              (p) => p.getBoundingClientRect().height > 30,
            ).length,
            cut: [...document.querySelectorAll("[data-card] p > time")].filter(
              (t) => t.scrollWidth > t.clientWidth + 1 && getComputedStyle(t).display !== "inline",
            ).length,
          }));
          expect(found, `${name} at ${width}`).toEqual({ wide: expect.any(Number), tall: 0, cut: 0 });
          expect(found.wide, `${name} at ${width}`).toBeLessThanOrEqual(0);
        }
      }
    });

  test("a desk uses its width", async ({ page }) => {
    await page.setViewportSize(DESK);
    await page.goto("/");
    const right = await page
      .locator("main h2, main h3")
      .evaluateAll((l) => Math.max(...l.map((e) => e.getBoundingClientRect().right)));
    const left = await page
      .locator("main h2, main h3")
      .evaluateAll((l) => Math.min(...l.map((e) => e.getBoundingClientRect().left)));
    expect(right - left).toBeGreaterThan(1000);
    const { article } = await places("sw");
    await page.goto(article ?? "");
    expect(
      await page.locator('article[data-page="article"]').evaluate((e) => e.getBoundingClientRect().width),
    ).toBeLessThanOrEqual(704);
    await expect(page.locator("aside [data-card]").first()).toBeVisible();
  });

  test("a video list has its play mark on the lead only", async ({ page }) => {
    await page.goto("/video");
    expect(await page.locator("[data-card] .rounded-full svg").count()).toBe(1);
  });
});

test.describe("accessible", () => {
  for (const scheme of ["light", "dark"] as const)
    test(`axe finds nothing on any page: ${scheme}`, async ({ page }) => {
      test.setTimeout(180_000);
      await page.emulateMedia({ colorScheme: scheme, reducedMotion: "reduce" });
      for (const size of [PHONE, DESK]) {
        await page.setViewportSize(size);
        for (const [name, path] of Object.entries(await places("sw"))) {
          if (!path) continue;
          await ready(page, path);
          const { violations } = await new AxeBuilder({ page })
            .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
            // Text over photographs is judged by eye, over a gradient (design/public-experience.md).
            .exclude(".cover")
            .exclude('[data-card="short"]')
            .exclude("[data-shorts]")
            .analyze();
          expect(
            violations.map((v) => `${v.id}: ${v.nodes.map((n) => n.target).join(" | ")}`),
            `${name} ${size.width}`,
          ).toEqual([]);
        }
      }
    });

  test("the first stop is a link to the news, and one heading leads each page", async ({ page }) => {
    for (const [name, path] of Object.entries(await places("sw"))) {
      if (!path) continue;
      await page.goto(path);
      expect(await page.locator("h1").count(), name).toBe(1);
    }
    await page.goto("/");
    await page.keyboard.press("Tab");
    await expect(page.locator(":focus")).toHaveAttribute("href", "#main");
  });

  test("targets a thumb can hit", async ({ page }) => {
    await page.setViewportSize(PHONE);
    for (const path of ["/", "/profile", "/search"]) {
      await page.goto(path);
      const small = await page
        .locator("header a, header button, [data-bar] a, [data-bar] button, main button")
        .evaluateAll((l) =>
          l
            .map((e) => [e.outerHTML.slice(0, 80), e.getBoundingClientRect()] as const)
            .filter(([, r]) => r.width > 0 && r.height > 0 && r.height < 44)
            .map(([h]) => h),
        );
      // The wordmark's link is inside a 56 px bar that is all of it.
      expect(small.filter((h) => !h.includes("text-headline"))).toEqual([]);
    }
  });
});

test.describe("YouTube", () => {
  test("nothing of it is asked for before it is pressed", async ({ page }) => {
    const found = (await api("types/youtube?locale=sw")).results?.[0] ?? null;
    test.skip(!found, "the seed has no YouTube story");
    const asked: string[] = [];
    page.on("request", (r) => /youtube|google/.test(r.url()) && asked.push(r.url()));
    await page.route(/youtube-nocookie/, (r) =>
      r.fulfill({ contentType: "text/html", body: "<p>player</p>" }),
    );
    await ready(page, found.path);
    expect(asked.filter((u) => !u.includes("i.ytimg.com"))).toEqual([]);
    await page.locator('[data-do="youtube"]').first().click();
    await expect(page.locator('iframe[src^="https://www.youtube-nocookie.com/embed/"]')).toBeVisible();
  });
});
