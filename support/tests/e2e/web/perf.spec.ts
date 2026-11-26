import { chromium } from "@playwright/test";
import lighthouse from "lighthouse";
import { expect, places, test } from "./helpers";

// Lighthouse on the pages SPEC §7 names, as a phone on a slow 4G line sees them (Lighthouse's default throttling),
// the median of three runs. INP needs a person; in the lab its stand-ins are total blocking time and one real tap.
const PORT = 9333;
const RUNS = 3;
// TBT stands in for INP in the lab. Scores: performance ≥ 95, accessibility and SEO 100, best practices ≥ 95.
const BUDGET = { lcp: 2000, cls: 0.05, tbt: 150, inp: 200, articleJs: 120 * 1024 };
const SCORES = { performance: 0.95, accessibility: 1, seo: 1, "best-practices": 0.95 } as const;
const median = (xs: number[]) => [...xs].sort((a, b) => a - b)[Math.floor(xs.length / 2)];

test.describe.configure({ mode: "serial" });
test.setTimeout(300_000);

const measured: Record<string, Record<string, number>> = {};

test.afterAll(() => {
  // The numbers, for the step summary and the pull request.
  console.log(
    [
      "| Page | LCP ms | CLS | TBT ms | Script KB (gzip) | Perf | A11y | SEO | BP |",
      "|---|---|---|---|---|---|---|---|---|",
    ]
      .concat(
        Object.entries(measured).map(
          ([p, m]) =>
            `| ${p} | ${m.lcp} | ${m.cls.toFixed(3)} | ${m.tbt} | ${(m.js / 1024).toFixed(1)} | ${m.performance} | ${m.accessibility} | ${m.seo} | ${m["best-practices"]} |`,
        ),
      )
      .join("\n"),
  );
});

for (const name of ["home", "article", "category", "video", "live"])
  test(`Lighthouse: ${name}`, async () => {
    const path = (await places("sw"))[name] as string;
    const browser = await chromium.launch({ args: [`--remote-debugging-port=${PORT}`] });
    try {
      const runs = [];
      for (let i = 0; i < RUNS; i++) {
        const result = await lighthouse(`http://localhost:3000${path}`, {
          port: PORT,
          output: "json",
          logLevel: "error",
          onlyCategories: Object.keys(SCORES),
        });
        const a = result?.lhr.audits ?? {};
        const requests =
          (a["network-requests"]?.details as { items?: { resourceType: string; transferSize: number }[] })
            ?.items ?? [];
        runs.push({
          lcp: a["largest-contentful-paint"]?.numericValue ?? Infinity,
          cls: a["cumulative-layout-shift"]?.numericValue ?? Infinity,
          tbt: a["total-blocking-time"]?.numericValue ?? Infinity,
          js: requests.filter((r) => r.resourceType === "Script").reduce((s, r) => s + r.transferSize, 0),
          ...Object.fromEntries(
            Object.keys(SCORES).map((c) => [c, Math.round((result?.lhr.categories[c]?.score ?? 0) * 100)]),
          ),
        });
      }
      const m = {
        lcp: Math.round(median(runs.map((r) => r.lcp))),
        cls: median(runs.map((r) => r.cls)),
        tbt: Math.round(median(runs.map((r) => r.tbt))),
        js: median(runs.map((r) => r.js)),
        ...Object.fromEntries(
          Object.keys(SCORES).map((c) => [c, median(runs.map((r) => (r as never)[c] as number))]),
        ),
      };
      measured[name] = m;
      expect.soft(m.lcp, "LCP").toBeLessThan(BUDGET.lcp);
      expect.soft(m.cls, "CLS").toBeLessThan(BUDGET.cls);
      expect.soft(m.tbt, "TBT").toBeLessThan(BUDGET.tbt);
      if (name === "article") expect.soft(m.js, "article script, gzipped").toBeLessThan(BUDGET.articleJs);
      for (const [c, least] of Object.entries(SCORES))
        expect.soft((m as Record<string, number>)[c], `${c} score`).toBeGreaterThanOrEqual(least * 100);
    } finally {
      await browser.close();
    }
  });

test("INP: the slowest answer to a tap on an article", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto((await places("sw")).article as string);
  await page.waitForLoadState("networkidle");
  await page.evaluate(() => {
    (window as unknown as { inp: number }).inp = 0;
    new PerformanceObserver((list) => {
      for (const e of list.getEntries()) {
        const w = window as unknown as { inp: number };
        if ((e as PerformanceEventTiming).interactionId) w.inp = Math.max(w.inp, e.duration);
      }
    }).observe({ type: "event", buffered: true, durationThreshold: 16 } as PerformanceObserverInit);
  });
  // What a reader presses on a story: text size, save, share (copied, since there is no share sheet here).
  for (const control of await page.locator("[data-bar] button").all()) {
    await control.click();
    await page.waitForTimeout(150);
  }
  await page.mouse.wheel(0, 1200);
  await page.waitForTimeout(500);
  const inp = await page.evaluate(() => (window as unknown as { inp: number }).inp);
  console.log(`INP (lab, the slowest tap): ${Math.round(inp)} ms`);
  expect(inp).toBeLessThan(BUDGET.inp);
});
