import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { ArticleBody, type ContentContext } from "../src/content";
import type { Asset } from "../src/media";

const dir = resolve(import.meta.dirname, "../../../docs/content-fixtures");
const load = (kind: string) =>
  readdirSync(`${dir}/${kind}`).map(
    (f) => [f, JSON.parse(readFileSync(`${dir}/${kind}/${f}`, "utf8"))] as const,
  );

const image = (id: string): Asset => ({
  kind: "image",
  id,
  alt: "Picha",
  credit: "Mfano",
  width: 1600,
  height: 900,
  color: "#aabbcc",
  focal: [500, 500],
  base: `media/i/${id}/`,
  widths: [320, 640],
  crops: "",
});
const video = (id: string): Asset => ({
  kind: "video",
  id,
  alt: "Video",
  credit: "",
  width: 1280,
  height: 720,
  color: "",
  duration_ms: 1000,
  hls: "h.m3u8",
  poster: "p.jpg",
  sprite: "",
  sprite_vtt: "",
});
function context(document: unknown): ContentContext {
  const text = JSON.stringify(document);
  const assets: Record<string, Asset> = {};
  for (const [, id] of text.matchAll(/"asset":"([0-9a-f-]+)"/g)) assets[id as string] = image(id as string);
  for (const [, id] of text.matchAll(/"type":"video","id":"[^"]+","asset":"([0-9a-f-]+)"/g))
    assets[id as string] = video(id as string);
  return {
    assets,
    links: {},
    mediaBase: "https://cdn.example",
    interactive: true,
    formatTime: (iso) => iso.slice(11, 16),
    labels: {
      play: "Cheza",
      playError: "Imeshindikana",
      sensitive: "Nyeti",
      readAlso: "Soma pia",
      openPost: "Fungua",
      unsupported: "Haipatikani",
      pinned: "Imebandikwa",
      gallery: "Picha",
    },
  };
}
const render = (document: unknown) =>
  renderToStaticMarkup(<ArticleBody document={document} context={context(document)} />);

describe("every valid fixture", () => {
  it.each(load("valid"))("%s renders as reviewed", (_, document) => {
    expect(render(document)).toMatchSnapshot();
  });
});

describe("every invalid fixture", () => {
  it.each(load("invalid"))("%s never throws and never runs anything", (_, document) => {
    const html = render(document);
    expect(html).not.toMatch(/<script|javascript:|data:text|onerror=/i);
  });
});

describe("details", () => {
  const one = (block: object) => render({ version: 1, blocks: [{ id: "block-1", ...block }] });
  it("shows text that looks like HTML as text", () =>
    expect(one({ type: "paragraph", content: [{ type: "text", text: "<img src=x onerror=1>" }] })).toContain(
      "&lt;img",
    ));
  it("leaves no dead link to a post that is gone", () =>
    expect(
      one({ type: "related_link", title: "Soma", post: "0197a000-0000-7000-8000-000000000001" }),
    ).not.toContain("<a"));
  it("covers sensitive pictures", () =>
    expect(
      one({ type: "image", asset: "0197a000-0000-7000-8000-000000000001", alt: "x", sensitive: true }),
    ).toContain("<details"));
  it("loads nothing from YouTube before it is asked", () => {
    const html = one({ type: "youtube", videoId: "aqz-KE-bpKQ", title: "Filamu" });
    // The video's id is in a data attribute for the island; nothing is fetched from YouTube: no frame, no address.
    expect(html).not.toMatch(/(src|href|srcSet)="[^"]*youtube/);
    expect(html).not.toContain("ytimg");
    expect(html).not.toContain("iframe");
  });
  it("keeps space for a picture before it loads", () =>
    expect(one({ type: "image", asset: "0197a000-0000-7000-8000-000000000001", alt: "x" })).toMatch(
      /width="1600" height="900"/,
    ));
  it("offers every format and width", () => {
    const html = one({ type: "image", asset: "0197a000-0000-7000-8000-000000000001", alt: "x" });
    for (const name of ["320.avif 320w", "640.webp 640w", "640.jpg 640w"]) expect(html).toContain(name);
  });
  it("places a calm note where a future block would be", () =>
    expect(one({ type: "hologram" })).toContain("Haipatikani"));
});
