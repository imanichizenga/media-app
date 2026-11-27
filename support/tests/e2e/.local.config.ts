import { defineConfig } from "@playwright/test";
export default defineConfig({
  testDir: "./web",
  testMatch: [
    "accounts.spec.ts",
    "experience.spec.ts",
    "search.spec.ts",
    "states.spec.ts",
    "site.spec.ts",
    "seo.spec.ts",
    "contract.spec.ts",
  ],
  timeout: 60_000,
  workers: 2,
  reporter: "list",
  use: { baseURL: "http://localhost:3000", locale: "sw-TZ", timezoneId: "Africa/Dar_es_Salaam" },
});
