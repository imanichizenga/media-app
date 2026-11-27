import { AxeBuilder } from "@axe-core/playwright";
import type { Page } from "@playwright/test";
import { expect, PHONE, places, ready, test } from "./helpers";

/** A number nobody else in this run uses: each test is a new reader. */
const fresh = () => `78${String(Date.now() % 10_000_000).padStart(7, "0")}`;

async function signIn(page: Page, phone = fresh(), name = "Asha Majaribio") {
  await page.locator('[data-form="phone"] input[name=phone]').fill(phone);
  await page.locator('[data-form="phone"] button[type=submit]').click();
  const local = page.locator("[data-local-code]");
  await expect(local).toBeVisible();
  const code = ((await local.textContent()) ?? "").replace(/\D/g, "").slice(-6);
  await page.locator("#auth-code").fill(code); // six digits send it by themselves
  await expect(page.locator('[data-step="name"]')).toBeVisible();
  await page.locator("#auth-name").fill(name);
  await page.locator("input[name=accept_terms]").check();
  await page.locator('[data-form="name"] button[type=submit]').click();
  await expect(page.locator("dialog[open]")).toHaveCount(0);
}

test.describe("readers' accounts (ADR-0050)", () => {
  test("a guest who taps the heart signs in with a phone, and the like is done after", async ({ page }) => {
    const { article } = await places("sw");
    await page.setViewportSize(PHONE);
    await ready(page, article ?? "/");
    const heart = page.locator("[data-like]:visible").first();
    await heart.click();
    const sheet = page.getByRole("dialog");
    await expect(sheet).toBeVisible();
    await expect(sheet.getByRole("heading", { level: 2 }).first()).toHaveText("Ingia ili kupenda habari hii");
    await signIn(page);
    await expect(page.locator("#toast")).toHaveText("Karibu, Asha Majaribio!");
    await expect(heart).toHaveAttribute("aria-pressed", "true");
    // The You place wears the reader's initial (an article's foot is its own actions: Home has the places).
    await ready(page, "/");
    await expect(page.locator("[data-bar] [data-me-badge]")).toHaveText("A");
  });

  test("a wrong code says how many tries are left", async ({ page }) => {
    await page.setViewportSize(PHONE);
    await ready(page, "/profile");
    await page.getByRole("button", { name: "Ingia" }).click();
    await page.locator('[data-form="phone"] input[name=phone]').fill(fresh());
    await page.locator('[data-form="phone"] button[type=submit]').click();
    await expect(page.locator("[data-local-code]")).toBeVisible();
    const right = ((await page.locator("[data-local-code]").textContent()) ?? "")
      .replace(/\D/g, "")
      .slice(-6);
    await page.locator("#auth-code").fill(right === "000000" ? "111111" : "000000");
    await expect(page.locator("[data-auth-error]")).toHaveText("Msimbo si sahihi. Majaribio 4 yamebaki.");
    await expect(page.locator("[data-auth-error]")).toHaveAttribute("role", "alert");
  });

  test("a signed-in reader comments, replies and deletes; the count follows", async ({ page }) => {
    const { article } = await places("sw");
    await ready(page, "/profile");
    await page.getByRole("button", { name: "Ingia" }).click();
    await signIn(page, fresh(), "Baraka Mtoa Maoni");
    await ready(page, article ?? "/");
    await page.locator("#comments").scrollIntoViewIfNeeded();
    await page.locator("#comment-body").fill("Habari nzuri sana!");
    await page.getByRole("button", { name: "Tuma" }).click();
    const mine = page.locator("[data-comment-list] > li").first();
    await expect(mine.locator("[data-body]")).toHaveText("Habari nzuri sana!");
    await expect(mine.locator("[data-name]")).toHaveText("Baraka Mtoa Maoni");
    await mine.getByRole("button", { name: "Futa" }).click();
    await expect(
      page.locator("[data-comment-list] [data-body]", { hasText: "Habari nzuri sana!" }),
    ).toHaveCount(0);
  });

  test("views show on cards before opening; the story says views and readers, and who read it", async ({
    page,
  }) => {
    const { article } = await places("sw");
    await ready(page, article ?? "/");
    const stats = page.locator("[data-stats]");
    await expect(stats.locator('[data-n="views"]')).not.toHaveText("–");
    await expect(stats.locator('[data-n="readers"]')).not.toHaveText("–");
    await stats.getByRole("button").click();
    await expect(page.getByRole("dialog", { name: "Waliosoma habari hii" })).toBeVisible();
    await page.keyboard.press("Escape");
    await ready(page, "/");
    // On cards the counts are on the first line, never over the picture.
    await expect(
      page.locator('[data-counts]:not([hidden]) [data-c="views"]:not([hidden])').first(),
    ).toBeVisible();
  });

  test("the sheet is accessible, and closes with Escape", async ({ page }) => {
    await ready(page, "/profile");
    await page.getByRole("button", { name: "Ingia" }).click();
    const { violations } = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
      .include("dialog[open]")
      .analyze();
    expect(violations.map((v) => v.id)).toEqual([]);
    await page.keyboard.press("Escape");
    await expect(page.locator("dialog[open]")).toHaveCount(0);
  });

  test("signing out from You", async ({ page }) => {
    await ready(page, "/profile");
    await page.getByRole("button", { name: "Ingia" }).click();
    await signIn(page);
    await expect(page.locator("[data-reader]")).toBeVisible();
    await page.getByRole("button", { name: "Toka" }).click();
    await expect(page.locator("[data-guest]")).toBeVisible();
    expect(await page.evaluate(() => document.cookie.includes("signed=1"))).toBe(false);
  });
});
