import { execFileSync } from "node:child_process";
import { resolve } from "node:path";
import { test as base, type CDPSession, expect, type Page } from "@playwright/test";

const apiDir = resolve(import.meta.dirname, "../../../backend");
const env = {
  ...process.env,
  ENVIRONMENT: "dev",
  API_SURFACE: "admin",
  LOG_LEVEL: "ERROR",
  DATABASE_URL:
    process.env.E2E_DATABASE_URL ?? "postgresql://news_owner:local-dev-only@127.0.0.1:5432/news_e2e",
  REDIS_URL: "redis://127.0.0.1:6379/5",
  BROKER_URL: "redis://127.0.0.1:6379/6",
  STORAGE_ENDPOINT_URL: "http://127.0.0.1:8333",
  AWS_ACCESS_KEY_ID: "test",
  AWS_SECRET_ACCESS_KEY: "test",
  LOCAL_TRANSCODER: "1",
  LOCAL_SCANNER: "eicar",
};
export const manage = (...args: string[]) =>
  execFileSync(".venv/bin/python", ["manage.py", ...args], { cwd: apiDir, env, encoding: "utf8" }).trim();
export const sql = (query: string, database = "news_e2e") =>
  execFileSync(
    ".venv/bin/python",
    [
      "-c",
      "import psycopg,sys,os; psycopg.connect(os.environ['DSN'], autocommit=True).execute(sys.argv[1])",
      query,
    ],
    { cwd: apiDir, env: { ...env, DSN: env.DATABASE_URL.replace(/[^/]+$/, database) } },
  );
export const PASSWORD = "a calm editorial passphrase";

export async function virtualPasskey(page: Page): Promise<CDPSession> {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("WebAuthn.enable");
  await cdp.send("WebAuthn.addVirtualAuthenticator", {
    options: {
      protocol: "ctap2",
      transport: "internal",
      hasResidentKey: true,
      hasUserVerification: true,
      isUserVerified: true,
      automaticPresenceSimulation: true,
    },
  });
  return cdp;
}

/** Every test fails on a CSP violation, an uncaught error or a hydration mismatch. */
export const test = base.extend<{ problems: string[] }>({
  problems: [
    async ({ page }, use) => {
      const problems: string[] = [];
      page.on("pageerror", (e) => problems.push(`pageerror: ${e.message}`));
      page.on("console", (m) => {
        if (m.type() === "error" && !/Failed to load resource/.test(m.text())) problems.push(m.text());
      });
      await use(problems);
      expect(problems).toEqual([]);
    },
    { auto: true },
  ],
});
export { expect };

export async function english(page: Page) {
  await page.context().addCookies([{ name: "locale", value: "en", url: "http://localhost:3001" }]);
}

/** An invitation link, without the console: the invitation screen has its own tests. */
export const invitation = (email: string, role: string) =>
  manage(
    "shell",
    "-v0",
    "-c",
    [
      "from django.db import transaction",
      "from newsplatform.staff_security.staff import _create_invite",
      "with transaction.atomic():",
      `    print(_create_invite(None, "${email}", [{"role": "${role}"}])[1])`,
    ].join("\n"),
  );

/** Everything the browser complained about, including policy violations with their place. */
export function watch(page: Page, problems: string[]) {
  page.on("pageerror", (e) => problems.push(`pageerror: ${e.message}`));
  page.on("console", (m) => {
    if (m.type() === "error" && !/Failed to load resource/.test(m.text())) problems.push(m.text());
  });
  return page.addInitScript(() =>
    document.addEventListener("securitypolicyviolation", (e) =>
      console.error(
        `CSP ${location.pathname} ${e.violatedDirective} ${e.sourceFile}:${e.lineNumber}:${e.columnNumber} ${e.sample}`,
      ),
    ),
  );
}

export async function joinWithPasskey(
  page: Page,
  email: string,
  name: string,
  link = manage("bootstrap_super_admin", email),
) {
  await english(page);
  await virtualPasskey(page);
  await page.goto(link);
  await page.getByLabel("Full name").fill(name);
  await page.getByLabel("Password").fill(PASSWORD);
  await page.getByRole("button", { name: "Create account" }).click();
  await page.getByRole("button", { name: "Create a passkey" }).click();
  await expect(page.getByRole("list", { name: "Recovery codes" }).getByRole("listitem")).toHaveCount(10);
  await page.getByRole("button", { name: "I have saved them" }).click();
  await expect(page.getByRole("heading", { name: `Hello, ${name}` })).toBeVisible();
}
