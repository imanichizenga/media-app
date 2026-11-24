import { mkdirSync, readFileSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import type { Page } from "@playwright/test";
import { expect, joinWithPasskey, test } from "./helpers";

// Every screen in four combinations that cover each pair of device, theme and language.
// SCREENS=m0 or m1 chooses the milestone.
const M1 = process.env.SCREENS !== "m0";
const OUT = resolve(import.meta.dirname, `../../docs/design/screens/${M1 ? "m1" : "m0"}`);
const VARIANTS = [
  { device: "desktop", theme: "light", locale: "en" },
  { device: "desktop", theme: "dark", locale: "sw" },
  { device: "phone", theme: "light", locale: "sw" },
  { device: "phone", theme: "dark", locale: "en" },
] as const;
const SIZES = { desktop: { width: 1280, height: 800 }, phone: { width: 360, height: 740 } };
const M0_SCREENS: Record<string, string> = {
  dashboard: "/",
  integrations: "/integrations",
  "integration-detail": "/integrations/aws_s3",
  approvals: "/approvals",
  staff: "/staff",
  roles: "/roles",
  audit: "/audit",
  logs: "/logs",
  settings: "/settings",
  security: "/security",
};
const M1_SCREENS: Record<string, string> = {
  content: "/content",
  calendar: "/content/calendar",
  editor: "", // a published article, found while seeding
  media: "/media",
  taxonomy: "/taxonomy",
  author: "/author",
  settings: "/settings",
};
const SCREENS = M1 ? M1_SCREENS : M0_SCREENS;
const DATA = /\/api\/v1\/(?!auth\/session)/;

test.describe.configure({ mode: "serial" });
test.setTimeout(240_000);
let page: Page;

async function api(method: string, path: string, body: unknown) {
  return page.evaluate(
    async ([m, p, b]) => {
      const { csrf_token } = await (await fetch("/api/v1/auth/session")).json();
      const res = await fetch(`/api/v1/${p}`, {
        method: m as string,
        headers: { "content-type": "application/json", "x-csrf-token": csrf_token },
        body: JSON.stringify(b),
      });
      return res.status;
    },
    [method, path, body] as const,
  );
}

async function dress(v: (typeof VARIANTS)[number]) {
  await page.setViewportSize(SIZES[v.device]);
  await page.context().addCookies([
    { name: "theme", value: v.theme, url: "http://localhost:3001" },
    { name: "locale", value: v.locale, url: "http://localhost:3001" },
  ]);
}
const shoot = (name: string, v: (typeof VARIANTS)[number], state: string) =>
  page.screenshot({
    path: `${OUT}/${name}--${state}--${v.device}-${v.theme}-${v.locale}.jpg`,
    type: "jpeg",
    quality: 78,
    animations: "disabled",
  });

test.beforeAll(async ({ browser }) => {
  rmSync(OUT, { recursive: true, force: true });
  mkdirSync(OUT, { recursive: true });
  page = await (await browser.newContext({ locale: "en-GB", reducedMotion: "reduce" })).newPage();
});

test("before signing in", async () => {
  test.skip(M1);
  for (const v of VARIANTS) {
    await dress(v);
    await page.goto("/login");
    await expect(page.locator("input").first()).toBeVisible();
    await shoot("login", v, "loaded");
  }
});

test("realistic data", async () => {
  await joinWithPasskey(page, "amina@example.test", "Amina Mushi");
  if (M1) {
    const found = await page.evaluate(async () => {
      const res = await fetch("/api/v1/posts?type=article&status=published");
      return (await res.json()).results.find((p: { locales: string[] }) => p.locales.length === 2).id;
    });
    SCREENS.editor = `/content/${found}`;
    return;
  }
  for (const [email, role] of [
    ["juma.mwinyi@example.test", "journalist"],
    ["neema.kessy@example.test", "editor_in_chief"],
    ["baraka.lyimo@example.test", "moderator"],
  ])
    expect(await api("POST", "staff/invites", { email, grants: [{ role }] })).toBeLessThan(300);
  await page.request.put("http://127.0.0.1:5055/news-media", {
    data: '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><LocationConstraint>af-south-1</LocationConstraint></CreateBucketConfiguration>',
  });
  await page.goto("/integrations/aws_s3");
  await page.getByLabel("AWS region").fill("af-south-1");
  await page.getByLabel("Media bucket").fill("news-media");
  await page.getByLabel("CloudFront domain").fill("cdn.example.com");
  await page.getByLabel("CloudFront distribution ID").fill("E1ABCDEFGHIJKL");
  await page.getByRole("button", { name: "Save draft" }).click();
  await expect(page.getByText("Draft saved.")).toBeVisible();
  await page.getByRole("button", { name: "Run test" }).click();
  await expect(page.getByText("AWS is emulated here")).toBeVisible({ timeout: 20_000 });
});

for (const v of VARIANTS)
  test(`loaded and skeleton: ${v.device} ${v.theme} ${v.locale}`, async () => {
    await dress(v);
    for (const [name, path] of Object.entries(SCREENS)) {
      await page.goto(path);
      await expect(page.locator(".bone")).toHaveCount(0);
      await shoot(name, v, "loaded");
      let release = () => {};
      const gate = new Promise<void>((r) => {
        release = r;
      });
      await page.route(DATA, async (route) => {
        await gate;
        await route.continue();
      });
      await page.goto(path);
      await expect(page.locator("main .bone").first()).toBeVisible();
      await shoot(name, v, "skeleton");
      release();
      await expect(page.locator(".bone")).toHaveCount(0);
      await page.unroute(DATA);
    }
  });

for (const v of VARIANTS)
  test(`empty, error and offline: ${v.device} ${v.theme} ${v.locale}`, async () => {
    test.skip(M1);
    await dress(v);
    await page.goto("/approvals");
    await expect(page.locator(".bone")).toHaveCount(0);
    await shoot("approvals", v, "empty");
    const fail = (status?: number) =>
      page.route("**/api/v1/staff", (r) =>
        status
          ? r.fulfill({
              status,
              contentType: "application/problem+json",
              body: JSON.stringify({ code: "server_error", detail: "", status }),
            })
          : r.abort(),
      );
    for (const [state, status] of [
      ["error", 500],
      ["offline", undefined],
    ] as const) {
      await fail(status);
      await page.goto("/staff");
      await expect(page.locator("main .bone")).toHaveCount(0, { timeout: 20_000 });
      await shoot("staff", v, state);
      await page.unroute("**/api/v1/staff");
    }
  });

for (const v of VARIANTS)
  test(`inside the content screens: ${v.device} ${v.theme} ${v.locale}`, async () => {
    test.skip(!M1);
    await dress(v);
    const t = JSON.parse(
      readFileSync(resolve(import.meta.dirname, `../../apps/admin/messages/${v.locale}.json`), "utf8"),
    );
    const still = async () => {
      await expect(page.locator(".bone")).toHaveCount(0, { timeout: 20_000 });
      await page.waitForLoadState("networkidle");
    };
    await page.goto(SCREENS.editor as string);
    await still();
    for (const panel of ["details", "seo", "engagement", "history"]) {
      const tab = page.getByRole("tab", { name: t.content.panel[panel] });
      await tab.click();
      await still();
      await tab.scrollIntoViewIfNeeded();
      if (v.device === "phone")
        await page.locator("aside").evaluate((e) => e.scrollIntoView({ block: "start" }));
      await shoot("editor-panels", v, panel);
    }
    await page.getByRole("tab", { name: t.content.panel.publish }).click();
    await page.evaluate(() => scrollTo(0, 0));
    await page.getByRole("button", { name: t.editor.insert }).first().click();
    await shoot("editor-panels", v, "insert");
    await page.keyboard.press("Escape");
    await page.getByRole("button", { name: t.content.preview }).click();
    await expect(page.getByRole("dialog").getByRole("heading", { level: 1 })).toBeVisible();
    await still();
    await shoot("preview", v, "loaded");

    await page.goto("/content");
    await still();
    await page.getByRole("button", { name: t.content.new }).first().click();
    await shoot("content", v, "new-post");
    await page.keyboard.press("Escape");
    await page.getByRole("searchbox").fill("hakuna kitu kama hiki");
    await expect(page.getByText(t.content.empty)).toBeVisible();
    await shoot("content", v, "empty");

    await page.goto("/media");
    await still();
    await page.locator("main ul button").nth(20).click();
    await expect(page.getByRole("slider")).toBeVisible();
    await still();
    await shoot("media", v, "details");

    for (const tab of ["tags", "stories", "redirects"]) {
      await page.goto("/taxonomy");
      await page.getByRole("tab", { name: t.taxonomy.tab[tab] }).click();
      await still();
      await shoot("taxonomy", v, tab);
    }
    for (const [state, status] of [
      ["error", 500],
      ["offline", undefined],
    ] as const)
      for (const [name, path, url] of [
        ["content", "/content", "**/api/v1/posts?*"],
        ["media", "/media", "**/api/v1/media?*"],
      ] as const) {
        const pattern = new RegExp(url.replaceAll("**", "").replace("?*", "(\\?|$)"));
        await page.route(pattern, (r) =>
          status
            ? r.fulfill({
                status,
                contentType: "application/problem+json",
                body: JSON.stringify({ code: "server_error", detail: "", status }),
              })
            : r.abort(),
        );
        await page.goto(path);
        await expect(page.locator("main .bone")).toHaveCount(0, { timeout: 20_000 });
        await shoot(name, v, state);
        await page.unroute(pattern);
      }
  });
