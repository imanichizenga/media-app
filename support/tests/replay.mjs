// The public API as recorded from the demo seed, for machines that cannot run the real one (the iOS simulator's).
// node support/tests/replay.mjs [port]
import { existsSync, readFileSync } from "node:fs";
import { createServer } from "node:http";

const root = new URL("../../mobile/test/fixtures/", import.meta.url).pathname;
const data = {
  sw: JSON.parse(readFileSync(`${root}sw.json`)),
  en: JSON.parse(readFileSync(`${root}en.json`)),
};
const page = (results) => ({ results, next_cursor: null });
const config = {
  version: "1",
  media_base_url: "",
  versions: Object.fromEntries(
    ["android", "ios"].map((os) => [os, { minimum: "0.1.0", recommended: "", store: "https://example.com" }]),
  ),
  maintenance: { on: false, sw: "", en: "" },
  flags: { shorts: true, youtube: true, offline_saving: true },
  links: { about: "", editorial: "", corrections: "", contact: "", privacy: "", terms: "" },
  pinning: { enabled: false, pins: [] },
  identity: {
    brand_name: "Mfano News",
    tagline_sw: "",
    tagline_en: "",
    wordmark_light: null,
    wordmark_dark: null,
    symbol: null,
  },
  theme: {
    schema_version: 1,
    hash: "replay",
    key: "bold",
    color: "#b5121b",
    dark_color: "",
    css: "/theme/replay.css",
    theme_color: { light: "#0b0b0c", dark: "#0b0b0c" },
    tokens: { light: {}, dark: {} },
  },
  localization: { default_locale: "sw", timezone: "Africa/Dar_es_Salaam" },
};
function answer(url) {
  const d = data[url.searchParams.get("locale") ?? "sw"];
  const path = url.pathname.replace("/api/v1/", "");
  if (path === "app-config") return config;
  if (path === "content/home") return d.home;
  if (path === "content/navigation") return d.navigation;
  if (path === "content/latest") return page(d.latest);
  if (path === "content/types/short") return page(d.home.shorts);
  if (path === "content/types/video") return page(d.videos);
  if (path.startsWith("content/categories/")) return d.category;
  if (path.endsWith("/related")) return { results: d.related };
  if (path.startsWith("content/articles/")) return d.article;
  return null;
}
// Every request, its answer and how long it took: the evidence of a run (mobile-device.yml keeps it).
// Each line: seconds since start, the wall clock (UTC), and the client's port to match the app's NET lines.
const started = Date.now();
const stamp = (t = Date.now()) => `${((t - started) / 1000).toFixed(1)}s ${new Date(t).toISOString().slice(11, 23)}`;
const server = createServer((req, res) => {
  const url = new URL(req.url, "http://x");
  const at = Date.now();
  const port = req.socket.remotePort;
  console.log(`${stamp(at)} :${port} > ${req.method} ${url.pathname}${url.search}`);
  res.on("finish", () =>
    console.log(
      `${stamp()} :${port} ${req.method} ${url.pathname}${url.search} ${res.statusCode} ${Date.now() - at}ms`,
    ),
  );
  res.on("close", () => {
    if (!res.writableFinished) console.log(`${stamp()} :${port} closed before the answer: ${url.pathname}`);
  });
  const media = url.pathname.match(/^\/media\/[iv]\/([0-9a-f]+)\//);
  if (media) {
    const file = `${root}media/${media[1]}.jpg`;
    return existsSync(file)
      ? res.writeHead(200, { "content-type": "image/jpeg" }).end(readFileSync(file))
      : res.writeHead(404).end();
  }
  const body = answer(url);
  res.writeHead(body ? 200 : 404, { "content-type": "application/json" });
  res.end(JSON.stringify(body ?? { code: "not_found" }));
});
server.on("connection", (socket) => console.log(`${stamp()} :${socket.remotePort} accepted`));
server.listen(Number(process.argv[2] ?? 8010), "127.0.0.1", () => console.log(`${stamp()} listening`));
