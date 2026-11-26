import { again, ask, begin, go, inside, replace } from "./navigate";
import { keep, kept, remember, unkeep } from "./store";
import { playVideo, playYouTube, shorts, toggleShort, toggleSound } from "./video";

const root = document.documentElement;
const all = <E extends HTMLElement>(selector: string) => document.querySelectorAll<E>(selector);

// ---- how it looks ----
function wear(scheme: string) {
  if (scheme) root.dataset.theme = scheme;
  else delete root.dataset.theme;
  remember("scheme", scheme);
}
function textSize(n: number) {
  if (n) root.dataset.text = String(n);
  else delete root.dataset.text;
  remember("text", n ? String(n) : "");
}
const isDark = () =>
  root.dataset.theme === "dark" ||
  (!root.dataset.theme && matchMedia("(prefers-color-scheme: dark)").matches);

// ---- a word at the foot ----
let quiet: ReturnType<typeof setTimeout> | undefined;
function toast(text: string) {
  const el = document.getElementById("toast");
  if (!el) return;
  el.textContent = text;
  el.hidden = false;
  clearTimeout(quiet);
  quiet = setTimeout(() => {
    el.hidden = true;
  }, 2500);
}

// ---- saved ----
function marks() {
  const paths = new Set(kept().map((k) => k.path));
  for (const b of all('[data-do="save"]')) {
    const on = paths.has(b.dataset.path ?? "");
    b.setAttribute("aria-pressed", String(on));
    b.setAttribute("aria-label", (on ? b.dataset.unsave : b.dataset.save) ?? "");
  }
}
function savedList() {
  for (const box of all("[data-saved]")) {
    const list = kept();
    const ul = box.querySelector("ul");
    const row = box.querySelector<HTMLTemplateElement>("template[data-row]")?.content.firstElementChild;
    const empty = box.querySelector<HTMLElement>("[data-empty]");
    if (!ul || !row || !empty) continue;
    ul.replaceChildren(
      ...list.map((k) => {
        const li = row.cloneNode(true) as HTMLElement;
        const set = (selector: string, text: string) => {
          const el = li.querySelector(selector);
          if (el) el.textContent = text;
        };
        li.querySelector("a")?.setAttribute("href", k.path);
        set("[data-category]", k.category);
        set("[data-headline]", k.headline);
        const b = li.querySelector("button");
        b?.setAttribute("aria-label", `${b.getAttribute("aria-label")}: ${k.headline}`);
        if (b) b.dataset.path = k.path;
        return li;
      }),
    );
    ul.hidden = list.length === 0;
    empty.hidden = list.length > 0;
  }
}

// ---- coverage that goes on ----
let newer: Document | null = null;
setInterval(async () => {
  if (document.visibilityState !== "visible" || newer || all("[data-live]").length === 0) return;
  const at = location.href;
  const html = await again().catch(() => null);
  if (!html || location.href !== at) return;
  if (scrollY < 80) replace(html);
  else {
    newer = html;
    for (const el of all("[data-live]")) el.hidden = false;
  }
}, 30_000);

// ---- what is pressed ----
const DO: Record<string, (b: HTMLElement) => void> = {
  scheme: () => wear(isDark() ? "light" : "dark"),
  text: () => textSize((Number(root.dataset.text ?? 0) + 1) % 4),
  share: async (b) => {
    const url = location.origin + (b.dataset.path ?? location.pathname);
    try {
      if (navigator.share) await navigator.share({ title: b.dataset.title, url });
      else {
        await navigator.clipboard.writeText(url);
        toast(b.dataset.done ?? "");
      }
    } catch {
      // The reader closed it.
    }
  },
  save: (b) => {
    const { path = "", headline = "", category = "" } = b.dataset;
    if (b.getAttribute("aria-pressed") === "true") unkeep(path);
    else keep({ path, headline, category });
    marks();
  },
  unsave: (b) => {
    unkeep(b.dataset.path ?? "");
    savedList();
  },
  "close-app": () => {
    offers = false;
    remember("app-banner", "closed");
    for (const el of all("[data-app-banner]")) el.hidden = true;
  },
  live: () => {
    if (newer) replace(newer);
    newer = null;
    scrollTo({ top: 0 });
  },
  short: toggleShort,
  mute: toggleSound,
  video: playVideo,
  youtube: playYouTube,
};
const hydrated = "__next_f" in window; // `next dev` sends the framework: its own components do it
document.addEventListener("click", (e) => {
  if (e.defaultPrevented) return;
  const button = (e.target as Element | null)?.closest<HTMLElement>("[data-do]");
  const what = button?.dataset.do ?? "";
  if (button && DO[what] && !(hydrated && (what === "video" || what === "youtube"))) {
    DO[what](button);
    return;
  }
  if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
  const url = inside(e);
  if (!url) return;
  e.preventDefault();
  // The open place, tapped again: its top (N2).
  if (url.pathname + url.search === location.pathname + location.search)
    scrollTo({ top: 0, behavior: "smooth" });
  else {
    const card = (e.target as Element).closest("[data-card]");
    go(url, true, card?.querySelector("h2, h3")?.textContent ?? "");
  }
});
const near = (e: Event) => {
  const thrifty = (navigator as Navigator & { connection?: { saveData?: boolean } }).connection?.saveData;
  const url = thrifty ? null : inside(e);
  if (url && url.pathname + url.search !== location.pathname + location.search) ask(url).catch(() => {});
};
document.addEventListener("pointerdown", near, { passive: true });
let hover: ReturnType<typeof setTimeout> | undefined;
document.addEventListener(
  "pointerover",
  (e) => {
    clearTimeout(hover);
    if (e.pointerType === "mouse") hover = setTimeout(() => near(e), 80);
  },
  { passive: true },
);
document.addEventListener("input", (e) => {
  const el = e.target as HTMLInputElement;
  if (el.matches("[data-text-range]")) textSize(Number(el.value));
  else if (el.closest("[data-schemes]")) wear(el.value);
});

// ---- while one reads ----
let offers = false;
try {
  offers = /Android/.test(navigator.userAgent) && localStorage.getItem("app-banner") !== "closed";
} catch {}
let last = 0;
addEventListener(
  "scroll",
  () => {
    const y = scrollY;
    if (Math.abs(y - last) < 4) return;
    const end = y + innerHeight > root.scrollHeight - 80;
    const reading = document.querySelector("[data-reading-page]") !== null;
    if (reading && y > last && !end && y > 120) root.dataset.reading = "";
    else delete root.dataset.reading;
    last = y;
    // The first screen is for news: the app is offered to those who read on.
    if (offers && y > innerHeight) for (const el of all("[data-app-banner][hidden]")) el.hidden = false;
  },
  { passive: true },
);
const network = () => {
  for (const el of all("[data-offline]")) el.hidden = navigator.onLine;
};
addEventListener("online", network);
addEventListener("offline", network);
addEventListener("storage", () => {
  marks();
  savedList();
});

// ---- the line of meta (R2) ----
// Its parts wrap whole onto a hidden second line, so the reading time and then the time go by themselves. When the
// time has gone and the category has a short name, the short name is worn and the time comes back.
function fitMeta() {
  for (const line of all("[data-meta]") as NodeListOf<HTMLElement>) {
    const name = line.querySelector<HTMLElement>("[data-name]");
    const short = line.querySelector<HTMLElement>("[data-short]");
    const time = line.querySelector<HTMLElement>("[data-time]");
    if (!name || !short || !time) continue;
    name.hidden = false;
    short.hidden = true;
    if (time.offsetTop > name.offsetTop + 1) {
      name.hidden = true;
      short.hidden = false;
    }
  }
}
let fitting = 0;
addEventListener("resize", () => {
  cancelAnimationFrame(fitting);
  fitting = requestAnimationFrame(fitMeta);
});

// ---- a row of sections that goes on ----
// The sides with more are marked for the stylesheet (a fade), and their chevrons shown; a chevron goes most of a row on.
function tabs() {
  for (const row of all("[data-tabs]") as NodeListOf<HTMLElement>) {
    const list = row.querySelector("ul");
    if (!list) continue;
    const mark = () => {
      const before = list.scrollLeft > 1;
      const after = list.scrollLeft + list.clientWidth < list.scrollWidth - 1;
      row.toggleAttribute("data-before", before);
      row.toggleAttribute("data-after", after);
      for (const b of row.querySelectorAll<HTMLButtonElement>("[data-tabs-go]"))
        b.hidden = b.dataset.tabsGo === "1" ? !after : !before;
    };
    if (!row.dataset.ready) {
      row.dataset.ready = "";
      list.addEventListener("scroll", mark, { passive: true });
      addEventListener("resize", mark);
      for (const b of row.querySelectorAll<HTMLButtonElement>("[data-tabs-go]"))
        b.addEventListener("click", () =>
          list.scrollBy({
            left: Number(b.dataset.tabsGo) * list.clientWidth * 0.7,
            behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth",
          }),
        );
    }
    mark();
  }
}

// ---- each page ----
let stopShorts: (() => void)[] = [];
function arrive() {
  newer = null;
  last = scrollY;
  delete root.dataset.reading;
  marks();
  savedList();
  for (const el of all("[data-schemes] input") as NodeListOf<HTMLInputElement>)
    el.checked = el.value === (root.dataset.theme ?? "");
  for (const el of all("[data-text-range]") as NodeListOf<HTMLInputElement>)
    el.value = root.dataset.text ?? "0";
  // The open tab is in sight.
  for (const a of all('nav ul.overflow-x-auto a[aria-current="page"]')) {
    const ul = a.closest("ul");
    if (ul) ul.scrollLeft = a.offsetLeft - ul.clientWidth / 2 + a.offsetWidth / 2;
  }
  stopShorts = [...all("[data-shorts]")].map(shorts);
  fitMeta();
  tabs();
}
function leave() {
  for (const stop of stopShorts) stop();
  stopShorts = [];
}
begin(arrive, leave);
arrive();
network();
