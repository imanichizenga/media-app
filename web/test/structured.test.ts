import { describe, expect, test } from "vitest";
import { breadcrumbs, graph, json, newsArticle, organization, videoObject, website } from "@/lib/seo";
import { article, image, site, video } from "./data";
import { structured } from "./schema";

const ok = (...items: object[]) => structured.parse(JSON.parse(json(graph(...items))));
const trail = breadcrumbs([
  { name: "Mfano", path: "/" },
  { name: "Siasa", path: "/siasa" },
]);

describe("structured data", () => {
  test("an article, its trail, its publisher", () => {
    const made = ok(newsArticle(site, article), trail, organization(site), website(site, "sw"));
    const [news] = made["@graph"] as { image: string[]; publisher: { logo: { url: string } } }[];
    expect(news?.image).toEqual(
      ["16x9", "4x3", "1x1"].map((r) => `https://media.example/${image.crops}crop-${r}.jpg`),
    );
    // The logo is the database's, never ours.
    expect(news?.publisher.logo.url).toBe("http://localhost:3000/theme/s3.png");
  });
  test("a correction is said", () =>
    expect(JSON.stringify(newsArticle(site, { ...article, correction_note: "Tarehe" }))).toContain("Tarehe"));
  test("a live blog, while it runs and after", () => {
    const body = {
      version: 1,
      blocks: [
        {
          type: "live_update",
          id: "u1",
          time: "2026-11-25T06:30:00Z",
          title: "",
          blocks: article.body.blocks,
        },
      ],
    };
    const live = { ...article, type: "live_blog" as const, body } as typeof article;
    ok(newsArticle(site, live));
    const [ended] = ok(newsArticle(site, { ...live, live_ended_at: "2026-11-25T09:00:00Z" }))["@graph"];
    expect(ended).toMatchObject({ "@type": "LiveBlogPosting", coverageEndTime: "2026-11-25T09:00:00Z" });
  });
  test("a video of ours, and one of YouTube's", () => {
    ok(videoObject(site, { ...article, video, duration_ms: 95_000 } as never));
    const [tube] = ok(videoObject(site, { ...article, image: null, youtube_id: "dQw4w9WgXcQ" } as never))[
      "@graph"
    ];
    expect(tube).toMatchObject({ embedUrl: "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ" });
  });
  test("the validator itself refuses what is wrong", () => {
    expect(() => ok({ ...newsArticle(site, article), datePublished: "yesterday" })).toThrow();
    expect(() => ok({ ...newsArticle(site, article), hedline: "x" })).toThrow();
    expect(() => ok({ ...newsArticle(site, article), author: [] })).toThrow();
  });
  test("nothing in it can close its element", () => {
    const text = json({ a: "</script><script>alert(1)</script>\u2028" });
    expect(text).not.toContain("<");
    expect(text).not.toContain("\u2028");
    expect(JSON.parse(text).a).toContain("</script>");
  });
});
