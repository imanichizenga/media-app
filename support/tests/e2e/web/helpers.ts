import { existsSync, readFileSync } from "node:fs";
import type { Page } from "@playwright/test";
import { test as base, expect } from "../helpers";

const API = "http://127.0.0.1:8010/api/v1/content";
// biome-ignore lint/suspicious/noExplicitAny: the API's own contract is tested elsewhere
export const api = async (path: string): Promise<any> => (await fetch(`${API}/${path}`)).json();
export const PHONE = { width: 390, height: 844 };
export const SMALL = { width: 360, height: 640 };
export const DESK = { width: 1440, height: 900 };

/** One address of every kind of page, in one language. */
export async function places(locale: "sw" | "en") {
  const at = (p: string) => (locale === "sw" ? p : p === "/" ? "/en" : `/en${p}`);
  const [home, nav, live] = await Promise.all([
    api(`home?locale=${locale}`),
    api(`navigation?locale=${locale}`),
    api(`types/live_blog?locale=${locale}`),
  ]);
  const stories = home.sections.flatMap((s: { results: unknown[] }) => s.results);
  const of = (type: string) => stories.find((c: { type: string }) => c.type === type) ?? null;
  const story = of("article");
  const article = await api(`articles/${story.slug}?locale=${locale}`);
  const tagged = await Promise.all(
    stories.slice(0, 12).map((c: { slug: string }) => api(`articles/${c.slug}?locale=${locale}`)),
  );
  // A section with a page of stories (lead, cards and rows), whichever the seed filled.
  let category = nav[1].path;
  for (const n of nav as { slug: string; path: string }[]) {
    const found = await api(`categories/${n.slug}?locale=${locale}`);
    if ((found.results?.length ?? 0) >= 6) {
      category = n.path;
      break;
    }
  }
  return {
    home: at("/"),
    latest: at("/latest"),
    category,
    article: story.path,
    live: live.results[0]?.path,
    tag: tagged.find((a) => a.tags?.length)?.tags[0].path,
    cluster: tagged.find((a) => a.story)?.story.path,
    author: article.authors[0].path,
    video: at("/video"),
    "video-story": (await api(`types/video?locale=${locale}`)).results[0].path,
    shorts: at("/shorts"),
    search: at("/search"),
    // A word of a story's headline, so the results page has results.
    results: at(
      `/search?q=${encodeURIComponent(story.headline.split(" ").find((w: string) => w.length > 5) ?? story.headline)}`,
    ),
    saved: at("/saved"),
    profile: at("/profile"),
    page: at("/privacy"),
    missing: at("/hakuna-ukurasa/huu"),
  } as Record<string, string | undefined>;
}

/**
 * Pages are cached with stale-while-revalidate. Chrome answers a repeat fetch from its cache and revalidates in the
 * background, and Playwright never sees that request end, so "networkidle" would never come. Every page of a
 * context made by hand needs this too.
 */
export async function fresh(page: Page) {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send("Network.enable");
  await cdp.send("Network.setCacheDisabled", { cacheDisabled: true });
}
/** Violations of the policy are errors too, with their place. */
export const test = base.extend<{ policy: undefined }>({
  policy: [
    async ({ page }, use) => {
      await page.addInitScript(() =>
        document.addEventListener("securitypolicyviolation", (e) =>
          console.error(`CSP ${location.pathname} ${e.violatedDirective} ${e.blockedURI} ${e.sample}`),
        ),
      );
      await fresh(page);
      await use(undefined);
    },
    { auto: true },
  ],
});
/** Islands have arrived, and the skeletons with them. */
export async function ready(page: Page, path: string) {
  await page.goto(path);
  await page.waitForLoadState("networkidle");
}
/** What the website wrote to its log in this run (playwright.web.config.ts keeps it). */
export const WEB_LOG = new URL("../.web-server.log", import.meta.url).pathname;
export const webLog = () => (existsSync(WEB_LOG) ? readFileSync(WEB_LOG, "utf8") : "");
export { expect };
