import { mkdirSync, rmSync } from "node:fs";
import { resolve } from "node:path";
import type { Page } from "@playwright/test";
import { expect, joinWithPasskey, test } from "./helpers";

// Every screen in four combinations that cover each pair of device, theme and language.
const OUT = resolve(import.meta.dirname, "../../docs/design/screens/m0");
const VARIANTS = [
  { device: "desktop", theme: "light", locale: "en" },
  { device: "desktop", theme: "dark", locale: "sw" },
  { device: "phone", theme: "light", locale: "sw" },
  { device: "phone", theme: "dark", locale: "en" },
] as const;
const SIZES = { desktop: { width: 1280, height: 800 }, phone: { width: 360, height: 740 } };
const SCREENS: Record<string, string> = {
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
  for (const v of VARIANTS) {
    await dress(v);
    await page.goto("/login");
    await expect(page.locator("input").first()).toBeVisible();
    await shoot("login", v, "loaded");
  }
});

test("realistic data", async () => {
  await joinWithPasskey(page, "amina@example.test", "Amina Mushi");
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
