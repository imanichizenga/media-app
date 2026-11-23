import { defineConfig } from "@playwright/test";

const api = "cd ../../apps/api &&";
const env = {
  ENVIRONMENT: "dev",
  API_SURFACE: "admin",
  DJANGO_SETTINGS_MODULE: "config.settings.dev",
  DATABASE_URL:
    process.env.E2E_DATABASE_URL ?? "postgresql://news_owner:local-dev-only@127.0.0.1:5432/news_e2e",
  REDIS_URL: "redis://127.0.0.1:6379/5",
  BROKER_URL: "redis://127.0.0.1:6379/6",
  AWS_ENDPOINT_URL: "http://127.0.0.1:5055",
  AWS_ACCESS_KEY_ID: "test",
  AWS_SECRET_ACCESS_KEY: "test",
};
export default defineConfig({
  testDir: ".",
  workers: 1,
  timeout: 60_000,
  globalSetup: "./setup.ts",
  retries: 0,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : "list",
  use: { baseURL: "http://localhost:3001", trace: "retain-on-failure", locale: "en-GB" },
  webServer: [
    {
      command: `${api} .venv/bin/moto_server -p 5055`,
      url: "http://127.0.0.1:5055/moto-api/",
      timeout: 60_000,
    },
    {
      command: `${api} .venv/bin/uvicorn config.asgi:application --port 8001 --log-level warning`,
      env,
      url: "http://127.0.0.1:8001/health/live",
      timeout: 60_000,
    },
    {
      command: `${api} .venv/bin/celery -A config worker -Q critical,default -c 2 -l WARNING`,
      env,
      timeout: 60_000,
    },
    {
      command:
        "cp -r ../../apps/admin/.next/static ../../apps/admin/.next/standalone/apps/admin/.next/ && PORT=3001 HOSTNAME=localhost node ../../apps/admin/.next/standalone/apps/admin/server.js",
      url: "http://localhost:3001/healthz",
      timeout: 60_000,
    },
  ],
});
