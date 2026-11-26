import { defineConfig } from "@playwright/test";
import base, { env } from "./playwright.config";

const servers = Array.isArray(base.webServer) ? base.webServer : [];
const site = "../../../web/.next/standalone/web";
/** The website as readers get it, with the admin beside it: what is published there must appear here. */
export default defineConfig({
  ...base,
  testDir: "./web",
  testMatch: process.env.SCREENS
    ? "screens.spec.ts"
    : ["site.spec.ts", "seo.spec.ts", "contract.spec.ts", "states.spec.ts", "publish.spec.ts", "perf.spec.ts"],
  use: { ...base.use, baseURL: "http://localhost:3000", locale: "sw-TZ", timezoneId: "Africa/Dar_es_Salaam" },
  webServer: [
    ...servers,
    {
      command:
        "cd ../../../backend && .venv/bin/uvicorn config.asgi:application --port 8010 --log-level warning",
      env: { ...env, API_SURFACE: "public" },
      url: "http://127.0.0.1:8010/health/live",
      timeout: 60_000,
    },
    {
      // Its log is kept for the tests that read it (helpers.webLog), and still shown.
      command: `cp -r ../../../web/.next/static ${site}/.next/ && cp -r ../../../web/public ../../../web/fonts ${site}/ && node ${site}/server.js 2>&1 | tee .web-server.log`,
      env: {
        WEB_LOCAL: "1",
        API_BASE_URL: "http://127.0.0.1:8010",
        API_PROXY_TARGET: "http://127.0.0.1:8010",
        SITE_URL: "http://localhost:3000",
        REDIS_URL: "redis://127.0.0.1:6379/7",
        PORT: "3000",
        HOSTNAME: "localhost",
      },
      url: "http://localhost:3000/healthz",
      timeout: 60_000,
    },
  ],
});
