import { createServer } from "node:http";
import { AxeBuilder } from "@axe-core/playwright";
import type { Page } from "@playwright/test";
import { english, expect, joinWithPasskey, manage, PASSWORD, sql, test, watch } from "./helpers";

test.describe.configure({ mode: "serial" });
let page: Page;
const problems: string[] = [];
const PAGES = [
  "/",
  "/integrations",
  "/integrations/aws_s3",
  "/approvals",
  "/staff",
  "/roles",
  "/audit",
  "/logs",
  "/settings",
  "/security",
  "/content",
  "/content/calendar",
  "/media",
  "/taxonomy",
  "/author",
];

test.beforeAll(async ({ browser }) => {
  page = await (await browser.newContext({ locale: "en-GB" })).newPage();
  await watch(page, problems);
});
test.afterEach(() => expect(problems.splice(0)).toEqual([]));

test("a bootstrap invitation leads to a passkey-protected account", async () => {
  await joinWithPasskey(page, "amina@example.test", "Amina");
  expect(page.url()).not.toContain("#");
});

test("the session cookie is invisible to scripts", async () => {
  const cookie = (await page.context().cookies()).find((c) => c.name === "__Host-staff_session");
  expect(cookie).toMatchObject({ httpOnly: true, secure: true, sameSite: "Strict" });
  expect(await page.evaluate(() => document.cookie)).not.toContain("staff_session");
  expect(await page.evaluate(() => JSON.stringify({ ...localStorage, ...sessionStorage }))).toBe("{}");
});

test("the CSP is strict and the nonce changes every view", async () => {
  const csp = async () => (await page.request.get("/login")).headers()["content-security-policy"] ?? "";
  const [a, b] = [await csp(), await csp()];
  expect(a).not.toBe(b);
  expect(a).not.toContain("unsafe");
  expect(a).toContain("frame-ancestors 'none'");
});

test("sign out, then sign in with the passkey and return to where you were", async () => {
  await page.getByRole("button", { name: "Sign out" }).click();
  await expect(page).toHaveURL(/\/login/);
  await page.goto("/audit");
  await expect(page).toHaveURL(/\/login\?next=%2Faudit/);
  await page.getByLabel("Email").fill("amina@example.test");
  await page.getByLabel("Password").fill(PASSWORD);
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("button", { name: "Use a passkey" }).click();
  await expect(page).toHaveURL(/\/audit$/);
});

test("`next` cannot send people to another site", async () => {
  for (const next of ["https://evil.example", "//evil.example", "/\\evil.example"]) {
    await page.goto(`/login?next=${encodeURIComponent(next)}`);
    await page.getByLabel("Email").fill("amina@example.test");
    await page.getByLabel("Password").fill(PASSWORD);
    await page.getByRole("button", { name: "Continue" }).click();
    await page.getByRole("button", { name: "Use a passkey" }).click();
    await expect(page).toHaveURL("http://localhost:3001/");
  }
});

test("the audit chain verifies", async () => {
  await page.goto("/audit");
  await page.getByRole("button", { name: "Verify chain" }).click();
  await expect(page.getByText(/Intact: \d+ entries/)).toBeVisible();
});

test("an action taken before the session has loaded still completes", async () => {
  let release = () => {};
  const gate = new Promise<void>((r) => {
    release = r;
  });
  let held = false;
  await page.route("**/api/v1/auth/session", async (route) => {
    if (!held) {
      held = true;
      await gate;
    }
    await route.continue();
  });
  await page.goto("/audit");
  await page.getByRole("button", { name: "Verify chain" }).click();
  await expect(page.getByText(/Intact: \d+ entries/)).toBeVisible();
  const heldResponse = page.waitForResponse("**/api/v1/auth/session");
  release();
  await heldResponse;
  await page.unroute("**/api/v1/auth/session");
});

test("S3: the test reports each step, refuses an emulator, and blocks activation", async () => {
  await page.request.put("http://127.0.0.1:5055/news-media", {
    data: '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><LocationConstraint>af-south-1</LocationConstraint></CreateBucketConfiguration>',
  });
  await page.goto("/integrations/aws_s3");
  await page.getByLabel("AWS region").fill("af-south-1");
  await page.getByLabel("Access key ID").fill("AKIAIOSFODNN7EXAMPLE");
  await page.getByLabel("Secret access key").fill("super-secret-value-1234567890");
  await page.getByLabel("Media bucket").fill("news-media");
  await page.getByLabel("CloudFront domain").fill("cdn.example.com");
  await page.getByLabel("CloudFront distribution ID").fill("E1ABCDEFGHIJKL");
  await page.getByRole("button", { name: "Save draft" }).click();
  await expect(page.getByText("Draft saved.")).toBeVisible();
  await expect(page.getByLabel("Secret access key")).toHaveAttribute("placeholder", "••••7890");
  expect(await page.content()).not.toContain("super-secret-value");
  // Progress arrives over the socket: one ticketed connection, subscribed to this run and nothing else.
  const socket = page.waitForEvent("websocket");
  await page.getByRole("button", { name: "Run test" }).click();
  const signals: string[] = [];
  (await socket).on("framereceived", (f) => signals.push(String(f.payload)));
  const steps = page.getByRole("list", { name: "Test steps" });
  await expect(steps.getByText("Write probe object passed")).toBeVisible({ timeout: 20_000 });
  await expect(steps.getByText("Read it back passed")).toBeVisible();
  await expect(steps.getByText("AWS is emulated here")).toBeVisible();
  await expect(steps.getByText("Delete probe object passed")).toBeVisible();
  expect(signals.some((s) => s.includes('"ready"'))).toBe(true);
  expect(signals.join()).not.toMatch(/probe|news-media|AKIA/);
  await expect(page.getByRole("button", { name: "Activate version 1" })).toBeDisabled();
});

test("step-up interrupts, then finishes the original action", async () => {
  sql("UPDATE staff_security_staffsession SET mfa_verified_at = now() - interval '1 hour'");
  await page.goto("/staff");
  await page.getByRole("button", { name: "Invite" }).click();
  await page.getByLabel("Email").fill("juma@example.test");
  await page.getByLabel("Role").selectOption("journalist");
  await page.getByRole("button", { name: "Send invitation" }).click();
  await expect(page.getByRole("dialog", { name: "Confirm it's you" })).toBeVisible();
  await page.getByRole("button", { name: "Use a passkey" }).click();
  await expect(page.getByTestId("one-time-link")).toContainText("/invite#");
});

test("an invited journalist enrols with an authenticator app and sees only their sections", async ({
  browser,
}) => {
  const link = (await page.getByTestId("one-time-link").textContent()) ?? "";
  const other = await (await browser.newContext()).newPage();
  await english(other);
  await other.goto(link);
  await other.getByLabel("Full name").fill("Juma");
  await other.getByLabel("Password").fill(PASSWORD);
  await other.getByRole("button", { name: "Create account" }).click();
  await other.getByRole("button", { name: "Use an authenticator app" }).click();
  const secret = await other.locator("code").textContent();
  const code = manage("shell", "-v0", "-c", `import pyotp; print(pyotp.TOTP("${secret}").now())`);
  await other.getByLabel("6-digit code").fill(code);
  await other.getByRole("button", { name: "Verify" }).click();
  await other.getByRole("button", { name: "I have saved them" }).click();
  await expect(other.getByRole("heading", { name: "Hello, Juma" })).toBeVisible();
  const nav = other.getByRole("navigation", { name: "Main" });
  await expect(nav.getByRole("link")).toHaveText([
    "Dashboard",
    "Content",
    "Media library",
    "Categories and tags",
    "My author page",
    "My security",
  ]);
  await other.goto("/audit");
  await expect(other.getByText("You do not have permission to do this.")).toBeVisible();
  await other.close();
});

test("a role in one category reaches that category and nothing else", async ({ browser }) => {
  await page.goto("/staff");
  await page.getByRole("button", { name: "Invite" }).click();
  await page.getByLabel("Email").fill("rehema@example.test");
  await page.getByLabel("Role").selectOption("section_editor");
  await page.getByLabel("Where").selectOption({ label: "Sport" });
  await page.getByRole("button", { name: "Send invitation" }).click();
  const link = (await page.getByTestId("one-time-link").textContent()) ?? "";
  await page.keyboard.press("Escape");
  await expect(page.getByText("Section Editor · Sport")).toBeVisible();
  const other = await (await browser.newContext()).newPage();
  await joinWithPasskey(other, "rehema@example.test", "Rehema", link);
  await other.goto("/content");
  await other.getByRole("button", { name: "New post" }).first().click();
  const offered = await other.getByRole("dialog").getByLabel("Category").locator("option").allTextContents();
  expect(offered.map((o) => o.replace(/^(— )+/, ""))).toEqual(["Sport", "Football", "Athletics"]);
  await other.close();
});

test("four eyes: the requester cannot approve, a second person can", async ({ browser }) => {
  await page.goto("/settings");
  await page.getByLabel("Four-eyes approval").selectOption("on");
  const security = page.locator("section", {
    has: page.getByRole("heading", { name: "Security", exact: true }),
  });
  await security.getByRole("button", { name: "Save" }).click();
  await expect(security.getByText("Saved.")).toBeVisible();
  await security.getByLabel("Idle timeout (minutes)").fill("20");
  await security.getByRole("button", { name: "Save" }).click();
  await expect(security.getByText("Sent to a second person")).toBeVisible();
  await page.goto("/approvals");
  await expect(page.getByText("Change security settings")).toBeVisible();
  await expect(page.getByRole("button", { name: "Approve", exact: true })).toHaveCount(0);

  const other = await (await browser.newContext()).newPage();
  await joinWithPasskey(other, "baraka@example.test", "Baraka");
  await other.goto("/approvals");
  await other.getByRole("button", { name: "Approve", exact: true }).click();
  await other.getByLabel("Note").fill("Agreed");
  await other.getByRole("dialog").getByRole("button", { name: "Approve" }).click();
  await expect(other.getByText("Nothing is waiting")).toBeVisible();
  await other.goto("/settings");
  await expect(other.getByLabel("Idle timeout (minutes)")).toHaveValue("20");
  await other.close();
});

test("language, theme and command palette", async () => {
  await page.goto("/");
  await page.getByRole("button", { name: "Badili lugha kwenda Kiswahili" }).click();
  await expect(page.getByRole("heading", { name: "Habari, Amina" })).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("lang", "sw");
  await page.getByRole("button", { name: "Switch language to English" }).click();
  await expect(page.getByRole("heading", { name: "Hello, Amina" })).toBeVisible();
  await page.keyboard.press("ControlOrMeta+k");
  await page.keyboard.type("audit");
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/\/audit$/);
});

for (const theme of ["light", "dark"] as const)
  test(`accessible in the ${theme} theme`, async () => {
    await page.context().addCookies([{ name: "theme", value: theme, url: "http://localhost:3001" }]);
    for (const path of PAGES) {
      await page.goto(path);
      await expect(page.locator(".bone")).toHaveCount(0);
      const { violations } = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"])
        .analyze();
      expect
        .soft(
          violations.map((v) => `${v.id}: ${v.nodes.map((n) => n.html.slice(0, 90)).join(" | ")}`),
          path,
        )
        .toEqual([]);
    }
  });

test("phone layout: no sideways scroll, targets at least 44px", async () => {
  await page.setViewportSize({ width: 360, height: 740 });
  for (const path of PAGES) {
    await page.goto(path);
    await expect(page.locator(".bone")).toHaveCount(0);
    expect
      .soft(await page.evaluate(() => document.documentElement.scrollWidth), path)
      .toBeLessThanOrEqual(360);
    const cut = await page.evaluate(() =>
      [...document.querySelectorAll<HTMLElement>("main section:has(> table)")]
        .filter((e) => e.scrollWidth > e.clientWidth)
        .map((e) => `${e.ariaLabel} ${e.scrollWidth} > ${e.clientWidth}`),
    );
    expect.soft(cut, `${path}: tables must not be cut off`).toEqual([]);
    const small = await page.evaluate(() =>
      [...document.querySelectorAll<HTMLElement>("button, a[href], select, input:not([type=checkbox])")]
        .filter((e) => e.offsetParent && !e.matches(".sr-only"))
        .filter((e) => e.getBoundingClientRect().height < 44)
        .map(
          (e) =>
            `${e.tagName} ${e.textContent || e.getAttribute("name")} ${e.getBoundingClientRect().height}`,
        ),
    );
    expect.soft(small, path).toEqual([]);
  }
  await page.setViewportSize({ width: 1280, height: 800 });
});

test("skeletons match the loaded layout", async () => {
  const data = /\/api\/v1\/(?!auth\/session)/;
  for (const path of PAGES) {
    let release = () => {};
    const gate = new Promise<void>((r) => {
      release = r;
    });
    await page.route(data, async (route) => {
      await gate;
      await route.continue();
    });
    await page.goto(path);
    await expect.soft(page.locator("main .bone").first(), path).toBeVisible();
    await expect(
      page.getByRole("navigation", { name: "Main" }).getByRole("link", { name: "Dashboard" }),
    ).toBeVisible();
    await page.evaluate(() => {
      const w = window as unknown as { cls: number };
      w.cls = 0;
      new PerformanceObserver((list) => {
        for (const e of list.getEntries() as unknown as { value: number; hadRecentInput: boolean }[])
          if (!e.hadRecentInput) w.cls += e.value;
      }).observe({ type: "layout-shift", buffered: false });
    });
    const boxes = () =>
      page.evaluate(() => {
        const box = (s: string, keep: number[]) => {
          const r = document.querySelector(s)?.getBoundingClientRect();
          return r ? keep.map((i) => Math.round([r.x, r.y, r.width, r.height][i] ?? 0)) : null;
        };
        return {
          title: box("main h1", [0, 1]),
          // A day in the calendar is as tall as its news; nothing below it moves.
          row: box(
            "main tbody tr, main li",
            document.querySelector("main [data-grows]") ? [0, 1] : [0, 1, 3],
          ),
          field: box("main form input, main form .tap, main [data-skeleton=form] .tap", [0, 1, 3]),
        };
      });
    const before = await boxes();
    release();
    await expect(page.locator(".bone")).toHaveCount(0);
    const after = await boxes();
    for (const key of ["title", "row", "field"] as const) {
      const [a, b] = [before[key], after[key]];
      if (a && b)
        expect
          .soft(Math.max(...a.map((v, i) => Math.abs(v - (b[i] ?? 0)))), `${path} ${key}: ${a} vs ${b}`)
          .toBeLessThanOrEqual(8);
    }
    expect
      .soft(await page.evaluate(() => (window as unknown as { cls: number }).cls), `${path} CLS`)
      .toBeLessThan(0.05);
    await page.unroute(data);
  }
});

test("header buttons hold their place on phones until permissions arrive", async () => {
  await page.setViewportSize({ width: 360, height: 740 });
  for (const path of ["/staff", "/roles", "/audit", "/content", "/media", "/taxonomy"]) {
    let release = () => {};
    const gate = new Promise<void>((r) => {
      release = r;
    });
    await page.route("**/api/v1/**", async (route) => {
      await gate;
      await route.continue();
    });
    await page.goto(path);
    const top = () =>
      page.evaluate(() => document.querySelector("main table, main ul")?.getBoundingClientRect().y ?? 0);
    await expect(page.locator("main table .bone, main ul .bone").first()).toBeVisible();
    const before = await top();
    release();
    await expect(page.locator(".bone")).toHaveCount(0);
    expect.soft(Math.abs((await top()) - before), path).toBeLessThanOrEqual(8);
    await page.unroute("**/api/v1/**");
  }
  await page.setViewportSize({ width: 1280, height: 800 });
});

test("Trusted Types block script injection even from inside the page", async () => {
  const blocked = await page.evaluate(() => {
    const attempts: Record<string, () => void> = {
      html: () => {
        document.createElement("div").innerHTML = "<img src=x onerror=alert(1)>";
      },
      script: () => {
        document.createElement("script").src = "https://evil.example/x.js";
      },
    };
    return Object.entries(attempts)
      .filter(([, run]) => {
        try {
          run();
          return false;
        } catch {
          return true;
        }
      })
      .map(([k]) => k);
  });
  expect(blocked).toEqual(["html", "script"]); // eval is covered by the CSP test: DevTools-driven code may always eval
  problems.length = 0; // the browser logs each refusal
});

test("an uncaught error is reported without personal data, through our own origin", async () => {
  const received: string[] = [];
  const sink = createServer((req, res) => {
    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
    });
    req.on("end", () => {
      received.push(`${req.url}\n${body}`);
      res.end("{}");
    });
  }).listen(5056, "127.0.0.1");
  const outside: string[] = [];
  page.on("request", (r) => new URL(r.url()).host !== "localhost:3001" && outside.push(r.url()));
  try {
    await page.goto("/settings");
    await expect(page.locator(".bone")).toHaveCount(0);
    await page.evaluate(() => {
      setTimeout(() => {
        throw new TypeError("boom for amina@example.test");
      });
    });
    await expect.poll(() => received.length, { timeout: 10_000 }).toBe(1);
  } finally {
    sink.close();
  }
  expect(received[0]).toContain("/api/7/envelope/?sentry_version=7&sentry_key=key");
  expect(received[0]).toContain("TypeError");
  expect(received[0]).toContain("boom for [redacted]");
  expect(received[0]).not.toMatch(/amina|cookie|breadcrumb/i);
  expect(outside).toEqual([]);
  problems.length = 0; // the error was ours
});

test("a dropped connection is explained and recoverable", async () => {
  await page.goto("/");
  await page.route("**/api/v1/staff", (r) => r.abort());
  await page.getByRole("link", { name: "Staff" }).click();
  await expect(page.getByText("You appear to be offline.")).toBeVisible({ timeout: 15_000 });
  await page.unroute("**/api/v1/staff");
  await page.getByRole("button", { name: "Try again" }).click();
  await expect(page.getByRole("cell", { name: "amina@example.test" })).toBeVisible();
});
