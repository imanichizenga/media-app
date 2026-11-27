import { AxeBuilder } from "@axe-core/playwright";
import { api, DESK, expect, PHONE, ready, SMALL, test } from "./helpers";

/** A word of a real headline, long enough to be a word and not a stop word. */
async function aWord(): Promise<{ word: string; headline: string }> {
  const latest = await api("latest?locale=sw&limit=20");
  for (const card of latest.results) {
    const word = card.headline.split(/\s+/).find((w: string) => /^[A-Za-z]{6,}$/.test(w));
    if (word) return { word, headline: card.headline };
  }
  throw new Error("No headline with a long word");
}

test.describe("search (ADR-0049)", () => {
  test("results come as one types, the field keeps its focus, and nothing reloads", async ({ page }) => {
    const { word, headline } = await aWord();
    await page.setViewportSize(PHONE);
    await ready(page, "/search");
    let documents = 0;
    page.on("request", (r) => r.isNavigationRequest() && documents++);
    const field = page.getByRole("combobox");
    await field.pressSequentially(word.toLowerCase(), { delay: 40 });
    // No Search pressed: the results come by themselves.
    await expect(page).toHaveURL(new RegExp(`/search\\?q=${word.toLowerCase()}$`));
    await expect(page.locator("#results")).toContainText(word.toLowerCase());
    expect(await page.locator("[data-results] h2, [data-results] h3").allTextContents()).toContain(headline);
    await expect(field).toBeFocused();
    await expect(field).toHaveValue(word.toLowerCase());
    await expect(page.locator("[data-search-status]")).not.toBeEmpty();
    await expect(page.locator("form[data-search]")).toHaveAttribute("aria-busy", "false");

    // A filter is a link that keeps the words.
    await page.getByRole("link", { name: "Mpya kwanza" }).click();
    await expect(page).toHaveURL(/sort=newest/);
    await expect(page.getByRole("link", { name: "Mpya kwanza" })).toHaveAttribute("aria-current", "true");
    await expect(page.getByRole("combobox")).toHaveValue(word.toLowerCase());
    await page.goBack();
    await expect(page).not.toHaveURL(/sort=/);

    // An empty field brings the sections back; Back from the first results is the sections too.
    await page.getByRole("button", { name: "Futa maneno" }).click();
    await expect(page.locator('[data-page="explore"]')).toBeVisible();
    await expect(page).toHaveURL(/\/search$/);
    expect(documents).toBe(0);
  });

  test("one letter is not a search; the words that came last win", async ({ page }) => {
    const { word } = await aWord();
    await ready(page, "/search");
    const field = page.getByRole("combobox");
    await field.fill("a");
    await page.waitForTimeout(600);
    await expect(page).toHaveURL(/\/search$/);
    // Typed on before the first answer came: only the last words are shown.
    await field.fill("qqzzxxyy");
    await field.fill(word);
    await expect(page).toHaveURL(new RegExp(`q=${word}$`));
    await expect(page.locator("#results")).toContainText(word);
  });

  test("a typing mistake still finds the story", async ({ page }) => {
    const { word, headline } = await aWord();
    const typo = `${word.slice(0, 3)}${word[3] === "x" ? "y" : "x"}${word.slice(4)}`.toLowerCase();
    await ready(page, `/search?q=${typo}`);
    expect(await page.locator("[data-results] h2, [data-results] h3").allTextContents()).toContain(headline);
  });

  test("nothing found says so, and offers the sections", async ({ page }) => {
    await ready(page, "/search?q=qqzzxxyy");
    await expect(page.getByRole("heading", { name: "Hakuna habari zinazolingana" })).toBeVisible();
    await expect(page.getByRole("link", { name: "Gundua" }).last()).toHaveAttribute("href", "/search");
  });

  test("the form and its filters work without script", async ({ browser }) => {
    const { word } = await aWord();
    const page = await (await browser.newContext({ javaScriptEnabled: false })).newPage();
    await page.goto("/search");
    await page.getByRole("combobox").fill(word);
    await page.getByRole("button", { name: "Tafuta" }).click();
    await expect(page).toHaveURL(new RegExp(`q=${word}`));
    await expect(page.locator("[data-results] [data-card]").first()).toBeAttached();
    await page.getByRole("link", { name: "Wiki iliyopita" }).click();
    await expect(page).toHaveURL(/since=7d/);
  });

  test("recent searches stay on this device, are chosen with the keys, and can be cleared", async ({
    page,
  }) => {
    const { word } = await aWord();
    await ready(page, "/search");
    const field = page.getByRole("combobox");
    await field.fill(word);
    await field.press("Enter");
    await expect(page.locator("#results")).toBeVisible();
    await expect(field).not.toBeFocused(); // searched on purpose: the keyboard goes
    await page.getByRole("button", { name: "Futa maneno" }).click();
    await expect(page.getByRole("option", { name: word })).toBeVisible();
    await field.press("ArrowDown");
    await expect(field).toHaveAttribute("aria-activedescendant", /search-suggest-r0/);
    await field.press("Enter");
    await expect(page).toHaveURL(new RegExp(`q=${word}$`));
    await field.fill("");
    await page.getByRole("button", { name: "Futa ulizotafuta" }).click();
    await expect(page.getByRole("listbox")).toBeHidden();
    expect(await page.evaluate(() => localStorage.getItem("searches"))).toBeNull();
  });

  test("the first result is in the first screen of a small phone", async ({ page }) => {
    const { word } = await aWord();
    await page.setViewportSize(SMALL);
    await ready(page, `/search?q=${word}`);
    const first = await page.locator("[data-results] [data-card]").first().boundingBox();
    const bar = await page.getByRole("navigation", { name: "Sehemu kuu" }).boundingBox();
    expect(first && bar && first.y + 60 < bar.y).toBe(true);
  });

  test("accessible, in both schemes", async ({ page }) => {
    const { word } = await aWord();
    await page.setViewportSize(DESK);
    for (const scheme of ["light", "dark"] as const) {
      await page.emulateMedia({ colorScheme: scheme });
      await ready(page, `/search?q=${word}`);
      await page.getByRole("combobox").fill("");
      await page.getByRole("combobox").fill(word);
      const { violations } = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
        .analyze();
      expect(violations.map((v) => `${scheme}: ${v.id}`)).toEqual([]);
    }
  });
});
