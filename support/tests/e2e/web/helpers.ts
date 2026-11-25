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
  return {
    home: at("/"),
    latest: at("/latest"),
    category: nav[1].path,
    article: story.path,
    live: live.results[0]?.path,
    tag: tagged.find((a) => a.tags?.length)?.tags[0].path,
    cluster: tagged.find((a) => a.story)?.story.path,
    author: article.authors[0].path,
    video: at("/video"),
    "video-story": (await api(`types/video?locale=${locale}`)).results[0].path,
    shorts: at("/shorts"),
    search: at("/search"),
    saved: at("/saved"),
    profile: at("/profile"),
    page: at("/privacy"),
    missing: at("/hakuna-ukurasa/huu"),
  } as Record<string, string | undefined>;
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
export { expect };
