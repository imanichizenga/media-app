// Takes the content the prototypes show from a seeded public API (`manage.py seed_demo`), and the pictures it names.
// API=http://127.0.0.1:8010 node capture.mjs
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

const API = process.env.API ?? "http://127.0.0.1:8010";
const root = new URL(".", import.meta.url).pathname;
const get = async (path, locale) => {
  const res = await fetch(`${API}/api/v1/content/${path}${path.includes("?") ? "&" : "?"}locale=${locale}`);
  if (!res.ok) throw new Error(`${path}: ${res.status}`);
  return res.json();
};
const files = new Set();
const note = (value) => {
  if (!value || typeof value !== "object") return;
  if (value.kind === "image") {
    // Two sizes are enough here, and AVIF is what browsers ask for first.
    value.widths = value.widths.filter((w) => w === 640 || w === 1280 || value.widths.length === 1);
    for (const w of value.widths) files.add(`${value.base}${w}.avif`);
  }
  if (value.kind === "video" && value.poster) files.add(value.poster);
  for (const inner of Object.values(value)) note(inner);
};
for (const locale of ["sw", "en"]) {
  const home = await get("home", locale);
  const everything = (await get("latest?limit=50", locale)).results;
  const articles = home.latest.concat(everything).filter((c) => c.type === "article" && c.image);
  let article;
  for (const card of articles) {
    article = await get(`articles/${card.slug}`, locale);
    if (article.body.blocks.length >= 9) break;
  }
  const live = home.live.find((c) => c.type === "live_blog");
  const data = {
    home,
    navigation: await get("navigation", locale),
    article,
    related: (await get(`articles/${article.slug}/related`, locale)).results,
    live: live ? await get(`articles/${live.slug}`, locale) : null,
    category: await get(`categories/${locale === "sw" ? "biashara" : "business"}`, locale),
    videos: (await get("types/video", locale)).results,
    latest: everything,
  };
  // Not every row is shown; the files stay small enough to review.
  data.home.sections = data.home.sections.slice(0, 5);
  note(data);
  mkdirSync(`${root}data`, { recursive: true });
  writeFileSync(`${root}data/${locale}.json`, `${JSON.stringify(data)}\n`);
}
rmSync(`${root}public/media`, { recursive: true, force: true });
for (const key of files) {
  const res = await fetch(`${API}/${key}`);
  if (!res.ok) throw new Error(`${key}: ${res.status}`);
  mkdirSync(dirname(`${root}public/${key}`), { recursive: true });
  writeFileSync(`${root}public/${key}`, Buffer.from(await res.arrayBuffer()));
}
console.log(`${files.size} pictures`);
