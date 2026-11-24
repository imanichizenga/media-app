import type { ContentDocument } from "@news/content-schema";
import { describe, expect, it } from "vitest";
import { checks } from "../lib/seo";

const body = (...texts: string[]): ContentDocument => ({
  version: 1,
  blocks: texts.map((text, i) => ({
    type: "paragraph",
    id: `block-${i}`,
    content: [{ type: "text", text }],
  })),
});
const base = {
  headline: "Barabara mpya ya Dodoma yafunguliwa rasmi",
  standfirst: "Wakazi wanasema safari sasa inachukua dakika ishirini badala ya saa mbili kama zamani.",
  slug: "barabara-mpya-ya-dodoma",
  seo_title: "",
  seo_description: "",
  focus_keyword: "",
  body: body("Neno ".repeat(260)),
  hasHero: true,
  heroAlt: "Barabara",
};
const state = (over: Partial<typeof base>, key: string) =>
  checks({ ...base, ...over }).find((c) => c.key === key)?.state;

describe("SEO checks", () => {
  it("accept a good article", () => {
    expect(state({}, "title")).toBe("good");
    expect(state({}, "description")).toBe("good");
    expect(state({}, "words")).toBe("good");
  });
  it("prefer the override", () => expect(state({ seo_title: "x".repeat(80) }, "title")).toBe("warn"));
  it("find what is missing", () => {
    expect(state({ headline: "" }, "title")).toBe("bad");
    expect(state({ heroAlt: "" }, "alt")).toBe("bad");
    expect(state({ hasHero: false }, "alt")).toBeUndefined();
    expect(state({}, "links")).toBe("warn");
  });
  it("count local links and related posts", () => {
    const linked = body("x");
    linked.blocks.push({
      type: "related_link",
      id: "block-9",
      title: "Soma",
      post: "0197a000-0000-7000-8000-000000000001",
    });
    expect(state({ body: linked }, "links")).toBe("good");
  });
  it("match a keyword whatever its case or accents", () => {
    expect(state({ focus_keyword: "BARABARA MPYA" }, "keywordTitle")).toBe("good");
    expect(state({ focus_keyword: "Barabara Mpya" }, "keywordSlug")).toBe("good");
    expect(state({ focus_keyword: "reli" }, "keywordTitle")).toBe("warn");
    expect(state({}, "keywordTitle")).toBeUndefined();
  });
});
