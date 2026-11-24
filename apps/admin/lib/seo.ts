import type { Block, ContentDocument, Inline } from "@news/content-schema";

export type Check = { key: string; state: "good" | "warn" | "bad"; values?: Record<string, number> };
type Input = {
  headline: string;
  standfirst: string;
  slug: string;
  seo_title: string;
  seo_description: string;
  focus_keyword: string;
  body: ContentDocument;
  hasHero: boolean;
  heroAlt: string;
};

const plain = (content: Inline[]) => content.map((n) => (n.type === "text" ? n.text : " ")).join("");
const inlines = (block: Block): Inline[][] => {
  switch (block.type) {
    case "paragraph":
    case "heading":
    case "quote":
    case "callout":
      return [block.content];
    case "list":
    case "factbox":
      return block.items.map((i) => i.content);
    case "live_update":
      return block.blocks.flatMap((b) => inlines(b as Block));
    default:
      return [];
  }
};
export const text = (body: ContentDocument) => body.blocks.flatMap(inlines).map(plain).join("\n");
const fold = (s: string) => s.normalize("NFKD").replace(/\p{M}/gu, "").toLowerCase();

/** Lengths are what search results show before they cut. Nothing here blocks publishing. */
export function checks(input: Input): Check[] {
  const title = input.seo_title || input.headline;
  const description = input.seo_description || input.standfirst;
  const body = text(input.body);
  const words = body.split(/\s+/).filter(Boolean).length;
  const sentences = body.split(/[.!?]+\s/).filter((s) => s.trim());
  const average = sentences.length ? words / sentences.length : 0;
  const links = JSON.stringify(input.body).match(/"href":"\/[^/"]?[^"]*"/g)?.length ?? 0;
  const related = input.body.blocks.filter((b) => b.type === "related_link" && b.post).length;
  const out: Check[] = [
    {
      key: "title",
      state: !title ? "bad" : title.length > 65 || title.length < 25 ? "warn" : "good",
      values: { n: title.length },
    },
    {
      key: "description",
      state: !description ? "bad" : description.length > 160 || description.length < 70 ? "warn" : "good",
      values: { n: description.length },
    },
    { key: "words", state: words >= 250 ? "good" : "warn", values: { n: words } },
    {
      key: "sentences",
      state: average <= 24 ? "good" : "warn",
      values: { n: Math.round(average) },
    },
    { key: "hero", state: input.hasHero ? "good" : "warn" },
    { key: "links", state: links + related > 0 ? "good" : "warn", values: { n: links + related } },
  ];
  if (input.hasHero) out.push({ key: "alt", state: input.heroAlt ? "good" : "bad" });
  const keyword = fold(input.focus_keyword.trim());
  if (keyword) {
    const opening = fold(body).slice(0, 600);
    out.push(
      { key: "keywordTitle", state: fold(title).includes(keyword) ? "good" : "warn" },
      { key: "keywordOpening", state: opening.includes(keyword) ? "good" : "warn" },
      {
        key: "keywordSlug",
        state: !input.slug || fold(input.slug).includes(keyword.replace(/\s+/g, "-")) ? "good" : "warn",
      },
    );
  }
  return out;
}
