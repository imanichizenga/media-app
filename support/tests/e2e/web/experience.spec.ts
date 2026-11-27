import { api, DESK, expect, PHONE, places, ready, test } from "./helpers";

test.describe("what makes the site pleasant to use", () => {
  test("a story saved is counted on the bookmark of the places, and said", async ({ page }) => {
    const { article } = await places("sw");
    await page.setViewportSize(PHONE);
    await ready(page, article ?? "/");
    await page.locator('[data-do="save"]:visible').first().click();
    await expect(page.locator("#toast")).toHaveText("Imewekwa kwenye Hifadhi.");
    // An article's foot is its own actions; the places, with the count, are on every other page.
    await page.getByRole("link", { name: "Rudi" }).click();
    const count = page.locator("[data-bar] [data-saved-count]");
    await expect(count).toBeVisible();
    await expect(count.locator("[data-n]")).toHaveText("1");
    await expect(count.locator("[data-said]")).toHaveText("Habari 1 zimehifadhiwa");
    await page.goBack();
    await page.locator('[data-do="save"]:visible').first().click();
    await expect(page.locator("#toast")).toHaveText("Imeondolewa kwenye Hifadhi.");
    await page.goForward();
    await expect(page.locator("[data-bar] [data-saved-count]")).toBeHidden();
  });

  test("from You into one of the site's pages, and straight back", async ({ page }) => {
    await page.setViewportSize(PHONE);
    await ready(page, "/profile");
    await expect(page.locator("[data-back]")).toHaveCount(0); // a place of the foot is where one goes back to
    await page.locator('main a[href="/privacy"]').click();
    await expect(page).toHaveURL(/\/privacy$/);
    await page.getByRole("link", { name: "Rudi" }).click();
    await expect(page).toHaveURL(/\/profile$/);
    // Opened directly, the arrow still goes to You.
    await ready(page, "/privacy");
    await expect(page.getByRole("link", { name: "Rudi" })).toHaveAttribute("href", "/profile");
  });

  test("a section's stories slide by, and its last card goes to the whole section", async ({ page }) => {
    await page.setViewportSize(DESK);
    await ready(page, "/");
    const rail = page.locator("[data-rail]").first();
    await rail.scrollIntoViewIfNeeded();
    const next = rail.locator('[data-tabs-go="1"]');
    await expect(next).toBeVisible();
    const list = rail.locator("ul");
    const before = await list.evaluate((u) => u.scrollLeft);
    await next.click();
    await expect.poll(() => list.evaluate((u) => u.scrollLeft)).toBeGreaterThan(before);
    await expect(rail.locator('[data-tabs-go="-1"]')).toBeVisible();
    const all = rail.locator("li:last-child a");
    const href = await page
      .locator("section:has([data-rail])")
      .first()
      .locator("h2 + a")
      .getAttribute("href");
    await expect(all).toHaveAttribute("href", href ?? "");
    // A phone swipes: no arrows there.
    await page.setViewportSize(PHONE);
    await expect(next).toBeHidden();
  });

  test("breaking news is first on every page, takes turns, and can be paused", async ({ page }) => {
    const home = await api("home?locale=sw");
    const now = Date.now();
    const hot = home.breaking.filter((c: { breaking_until: string }) => Date.parse(c.breaking_until) > now);
    test.skip(hot.length === 0, "Nothing is breaking in this data");
    for (const path of ["/", "/latest", "/search"]) {
      await ready(page, path);
      await expect(page.getByRole("region", { name: "Habari za dharura" })).toBeVisible();
    }
    // A breaking story's own page does not announce itself.
    await ready(page, hot[0].path);
    await expect(page.locator(`section.breaking a[href="${hot[0].path}"]`)).toHaveCount(0);
    if (hot.length > 1) {
      await page.clock.install();
      await ready(page, "/");
      const bar = page.locator("[data-breaking]");
      await expect(bar.locator("[data-slide][data-on]")).toHaveAttribute("data-slide", "0");
      await page.mouse.move(0, 0);
      await page.clock.runFor(6500);
      await expect(bar.locator("[data-slide][data-on]")).toHaveAttribute("data-slide", "1");
      await bar.getByRole("button", { name: "Simamisha habari za dharura" }).click();
      await page.clock.runFor(13000);
      await expect(bar.locator("[data-slide][data-on]")).toHaveAttribute("data-slide", "1");
      await expect(bar.getByRole("button", { name: "Endelea na habari za dharura" })).toBeVisible();
    }
  });

  test("a line under the top says how far down one is", async ({ page }) => {
    await page.setViewportSize(PHONE);
    await ready(page, "/");
    const scale = () =>
      page.evaluate(() => {
        const m = /matrix\(([\d.]+)/.exec(
          getComputedStyle(document.querySelector("[data-top]") as Element, "::after").transform,
        );
        return m ? Number(m[1]) : 0;
      });
    expect(await scale()).toBeLessThan(0.05);
    await page.evaluate(() => scrollTo(0, (document.documentElement.scrollHeight - innerHeight) / 2));
    await expect.poll(scale).toBeGreaterThan(0.3);
  });
});
