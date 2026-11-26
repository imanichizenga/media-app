/**
 * Moving inside the site: the next document is fetched (the same one the CDN keeps) and put in place of this one, with
 * its skeleton meanwhile. Anything unusual is an ordinary navigation, so nothing depends on this.
 */
type Got = { url: URL; html: Document };

/**
 * Trusted Types (lib/csp.ts): the only HTML this island parses is a document of this site, fetched from this origin
 * with no credentials, and parsed inert (DOMParser runs no script). The policy says so, once, by name.
 */
type Policy = { createHTML: (s: string) => string };
const trusted: Policy = (
  globalThis as {
    trustedTypes?: { createPolicy: (name: string, rules: Policy) => Policy };
  }
).trustedTypes?.createPolicy("navigate", { createHTML: (s) => s }) ?? { createHTML: (s) => s };
const parse = (html: string) => new DOMParser().parseFromString(trusted.createHTML(html), "text/html");
const LIFE = 15_000;
const PATIENCE = 90; // quicker than this, a skeleton would only flicker
const asked = new Map<string, { at: number; got: Promise<Got> }>();
const seen = new Map<string, { html: Document; scroll: number; at: number }>();
let skeletons: Promise<Document | null> | null = null;
let visit = 0;
let onArrive: () => void = () => {};
let onLeave: () => void = () => {};
let here = "";

const keyOf = (u: URL | Location) => u.pathname + u.search;
const english = () => document.documentElement.lang === "en";
const PLACES = new Set(["tag"]);
const STILL = /^(about|editorial-policy|corrections|contact|privacy|terms)$/;

/** Which skeleton an address wears, known before its page is. */
export function kindOf(path: string): string | null {
  const parts = path
    .replace(/^\/en(?=\/|$)/, "")
    .split("/")
    .filter(Boolean);
  const [first = "", second] = parts;
  if (parts.length === 0) return "home";
  if (first === "story") return "story"; // a story opens on its summary
  if (PLACES.has(first)) return "list";
  if (first === "author") return "author";
  if (second) return parts.length === 2 ? "article" : null;
  if (first === "video") return "video";
  if (first === "search") return "explore";
  if (first === "shorts") return "shorts";
  if (first === "saved" || first === "profile") return null;
  return STILL.test(first) ? "still" : "front";
}
export function inside(event: Event): URL | null {
  const link = (event.target as Element | null)?.closest?.("a");
  if (!link?.href || link.target || link.hasAttribute("download") || link.hasAttribute("hreflang"))
    return null;
  const url = new URL(link.href);
  if (url.origin !== location.origin || /\.|^\/(api|rss|feed|media|theme|og)(\/|$)/.test(url.pathname))
    return null;
  // A place on this page: the browser's own.
  if (keyOf(url) === keyOf(location) && url.hash) return null;
  return url;
}
export function ask(url: URL): Promise<Got> {
  const key = keyOf(url);
  const kept = asked.get(key);
  if (kept && Date.now() - kept.at < LIFE) return kept.got;
  const got = fetch(key, { headers: { accept: "text/html" }, credentials: "omit" }).then(async (res) => {
    const type = res.headers.get("content-type") ?? "";
    if (res.status >= 500 || !type.includes("text/html")) throw new Error(String(res.status));
    const end = new URL(res.url);
    end.hash = url.hash;
    return { url: end, html: parse(await res.text()) };
  });
  asked.set(key, { at: Date.now(), got });
  got.catch(() => asked.delete(key));
  if (asked.size > 20) asked.delete(asked.keys().next().value as string);
  return got;
}
const page = (d: Document) => d.getElementById("page");
const HEAD =
  "title,meta[name]:not([name=viewport]):not([name=theme-color]),meta[property],link[rel=canonical],link[rel=alternate]";
const styles = (d: Document) =>
  [...d.querySelectorAll("link[rel=stylesheet]")].map((l) => l.getAttribute("href"));

function put(html: Document, moveFocus: boolean): boolean {
  const next = page(html);
  const now = page(document);
  const worn = styles(document);
  // Another release, theme or language: begin again.
  if (!next || !now || html.documentElement.lang !== document.documentElement.lang) return false;
  if (styles(html).some((s) => !worn.includes(s))) return false;
  onLeave();
  for (const el of document.head.querySelectorAll(HEAD)) el.remove();
  for (const el of html.head.querySelectorAll(HEAD)) document.head.append(document.importNode(el, true));
  now.replaceChildren(...[...next.childNodes].map((n) => document.importNode(n, true)));
  if (moveFocus) {
    const main = document.getElementById("main");
    main?.setAttribute("tabindex", "-1");
    main?.focus({ preventScroll: true });
    const say = document.getElementById("say");
    if (say) say.textContent = document.title;
  }
  onArrive();
  return true;
}
function wear(kind: string | null, path: string, mine: number, headline = "") {
  if (!kind || !skeletons) return;
  skeletons.then((d) => {
    const now = page(document);
    const section = d?.querySelector<HTMLTemplateElement>('template[data-skeleton="section"]');
    const own = kind === "front" && section?.dataset.paths?.split(" ").includes(path) ? "section" : kind;
    const part = d?.querySelector<HTMLTemplateElement>(`template[data-skeleton="${own}"]`);
    if (!part || !now || visit !== mine || now.dataset.loading !== path) return;
    onLeave();
    now.replaceChildren(document.importNode(part.content, true));
    // The card one pressed already said it.
    const h1 = kind === "article" && headline ? now.querySelector("article h1") : null;
    if (h1) h1.textContent = headline;
    // The tab one is going to is marked at once.
    for (const a of now.querySelectorAll("nav a[aria-current]"))
      if (a.getAttribute("href") !== path) a.removeAttribute("aria-current");
    for (const a of now.querySelectorAll(`nav a[href="${CSS.escape(path)}"]`))
      a.setAttribute("aria-current", "page");
    scrollTo(0, 0);
  });
}
function keepPlace() {
  const now = page(document);
  if (!now || now.dataset.loading) return;
  const copy = document.cloneNode(true) as Document;
  seen.set(here, { html: copy, scroll: scrollY, at: Date.now() });
  if (seen.size > 12) seen.delete(seen.keys().next().value as string);
}
export async function go(url: URL, push = true, headline = ""): Promise<void> {
  const mine = ++visit;
  const now = page(document);
  if (!now) return location.assign(url);
  keepPlace();
  if (push) history.pushState(null, "", url);
  here = keyOf(url);
  now.dataset.loading = url.pathname;
  const timer = setTimeout(() => wear(kindOf(url.pathname), url.pathname, mine, headline), PATIENCE);
  try {
    const got = await ask(url);
    if (visit !== mine) return;
    clearTimeout(timer);
    delete now.dataset.loading;
    if (keyOf(got.url) !== keyOf(url)) history.replaceState(null, "", got.url);
    here = keyOf(got.url);
    if (!put(got.html, true)) return location.replace(got.url);
    const target = got.url.hash && document.getElementById(decodeURIComponent(got.url.hash.slice(1)));
    if (target) target.scrollIntoView();
    else scrollTo(0, 0);
  } catch {
    clearTimeout(timer);
    // The browser says what is wrong, in its own words.
    if (visit === mine) location.replace(url);
  }
}
/** The same page again, as it is now. Null when nothing changed. */
export async function again(): Promise<Document | null> {
  const url = new URL(location.href);
  asked.delete(keyOf(url));
  const got = await ask(url);
  const text = (d: Document) => d.querySelector("[data-body]")?.textContent;
  return text(got.html) === text(document) ? null : got.html;
}
export const replace = (html: Document) => put(html, false);

export function begin(arrive: () => void, leave: () => void) {
  onArrive = arrive;
  onLeave = leave;
  here = keyOf(location);
  if (!page(document)) return;
  history.scrollRestoration = "manual";
  addEventListener("popstate", () => {
    const key = keyOf(location);
    if (key === here) return;
    const kept = seen.get(key);
    keepPlace();
    here = key;
    if (kept && Date.now() - kept.at < 300_000 && put(kept.html, true)) {
      visit++;
      delete page(document)?.dataset.loading;
      scrollTo(0, kept.scroll);
    } else go(new URL(location.href), false);
  });
  // A reload keeps its place, as it would without us.
  addEventListener("pagehide", () => {
    try {
      sessionStorage.setItem("place", JSON.stringify([here, scrollY]));
    } catch {}
  });
  try {
    const [path, y] = JSON.parse(sessionStorage.getItem("place") ?? "[]");
    const [entry] = performance.getEntriesByType("navigation") as PerformanceNavigationTiming[];
    if (path === here && (entry?.type === "reload" || entry?.type === "back_forward")) scrollTo(0, y);
  } catch {}
  const idle = window.requestIdleCallback ?? ((f: () => void) => setTimeout(f, 1500));
  addEventListener("load", () =>
    idle(() => {
      skeletons = fetch(english() ? "/en/skeletons" : "/skeletons", { credentials: "omit" })
        .then(async (r) => (r.ok ? parse(await r.text()) : null))
        .catch(() => null);
    }),
  );
}
