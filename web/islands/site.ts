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
/** How many are kept, on the places' bookmark: one remembers there is something to come back to. */
function counts(pop = false) {
  const n = kept().length;
  for (const el of all("[data-saved-count]")) {
    el.hidden = n === 0;
    const shown = el.querySelector("[data-n]");
    const said = el.querySelector("[data-said]");
    if (shown) shown.textContent = n > 99 ? "99+" : String(n);
    if (said) said.textContent = (el.dataset.say ?? "").replace("#", String(n));
    if (pop) bounce(el);
  }
}
/** A short pop, started again if it is already running. */
function bounce(el: Element) {
  el.classList.remove("pop");
  void (el as HTMLElement).offsetWidth;
  el.classList.add("pop");
}
function marks() {
  counts();
  const paths = new Set(kept().map((k) => k.path));
  for (const b of all('[data-do="save"]')) {
    const on = paths.has(b.dataset.path ?? "");
    b.setAttribute("aria-pressed", String(on));
    b.setAttribute("aria-label", (on ? b.dataset.unsave : b.dataset.save) ?? "");
  }
}
/** The saved page's list (islands/saved.ts), fetched only where the page has one. */
function savedList() {
  if (document.querySelector("[data-saved]"))
    import("./saved").then((m) => m.savedList(kept())).catch(() => {});
}

// ---- coverage that goes on ----
// Only pages that are live have it: its own file (islands/live.ts), fetched there.
let live: Promise<typeof import("./live")> | null = null;
const coverage = () => {
  if (document.querySelector("[data-live]"))
    live ??= import("./live").then((m) => {
      m.watch(again, replace);
      return m;
    });
  live?.then((m) => m.reset());
};

// ---- what is pressed ----
const DO: Record<string, (b: HTMLElement) => void> = {
  scheme: () => wear(isDark() ? "light" : "dark"),
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
    const { path = "", headline = "", category = "", post } = b.dataset;
    const was = b.getAttribute("aria-pressed") === "true";
    if (was) unkeep(path);
    else keep({ path, headline, category, post });
    // A signed-in reader's saves go to the account too (islands/account.ts).
    dispatchEvent(new CustomEvent("kept", { detail: { post, on: !was } }));
    marks();
    counts(true);
    if (!was) bounce(b);
    const said = was ? b.dataset.undone : b.dataset.done;
    if (said) toast(said);
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
    live?.then((m) => m.show());
    scrollTo({ top: 0 });
  },
  short: toggleShort,
  mute: toggleSound,
  video: playVideo,
  youtube: playYouTube,
};
const hydrated = "__next_f" in window;
// Pages gone through inside the site in this tab: the arrow back goes back only when there is somewhere to go.
let steps = 0;
addEventListener("popstate", () => {
  steps = Math.max(0, steps - 1);
}); // `next dev` sends the framework: its own components do it
document.addEventListener("click", (e) => {
  if (e.defaultPrevented) return;
  const button = (e.target as Element | null)?.closest<HTMLElement>("[data-do]");
  const what = button?.dataset.do ?? "";
  if (button && DO[what] && !(hydrated && (what === "video" || what === "youtube"))) {
    DO[what](button);
    return;
  }
  if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
  // The arrow back: where one came from inside the site, or else where it points.
  if ((e.target as Element | null)?.closest("[data-back]") && steps > 0) {
    e.preventDefault();
    history.back();
    return;
  }
  const url = inside(e);
  if (!url) return;
  e.preventDefault();
  // The open place, tapped again: its top (N2).
  if (url.pathname + url.search === location.pathname + location.search)
    scrollTo({ top: 0, behavior: "smooth" });
  else {
    const card = (e.target as Element).closest("[data-card]");
    steps++;
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
    root.toggleAttribute("data-scrolled", y > 8);
    if (Math.abs(y - last) < 4) return;
    const end = y + innerHeight > root.scrollHeight - 80;
    // The top's row of sections: away while one reads down, back at any step up (globals.css).
    if (y > last && y > 160 && !end) root.dataset.down = "";
    else if (y < last || y <= 160) delete root.dataset.down;
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
  for (const row of all("[data-tabs], [data-rail]") as NodeListOf<HTMLElement>) {
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

// ---- readers' accounts and engagement (ADR-0050) ----
// Fetched where there is something of the kind (cards with counts, a story, the account card) or a reader signed in.
let accounts: Promise<typeof import("./account")> | null = null;
const account = () => {
  if (
    document.cookie.includes("signed=1") ||
    document.querySelector("[data-counts],[data-stats],[data-account]")
  )
    accounts ??= import("./account").then((m) => {
      m.start({ go, toast, bounce, remember, kept });
      return m;
    });
  accounts?.then((m) => m.arrive());
};

// ---- search (ADR-0049) ----
// Its own file, fetched only where there is a search field: every other page stays as light as it was.
let searching: Promise<void> | null = null;
const search = () => {
  if (!searching && document.querySelector("form[data-search]"))
    searching = import("./search")
      .then((m) =>
        m.searchAsOneTypes({
          go,
          ask,
          remember,
          fresh: () => {
            marks();
            fitMeta();
          },
        }),
      )
      .catch(() => {
        searching = null;
      });
};

// ---- breaking news, when there are several ----
// They take turns (islands/breaking.ts), fetched only when a page has more than one.
const breaking = () => {
  if (document.querySelector("[data-breaking]")) import("./breaking").then((m) => m.turns()).catch(() => {});
};

// ---- how far down one is ----
// Where the browser ties the line under the top to the scroll (globals.css), nothing is fetched; elsewhere
// islands/scrolled.ts says it.
if (!CSS.supports("animation-timeline: scroll()")) import("./scrolled").catch(() => {});

// ---- each page ----
let stopShorts: (() => void)[] = [];
function arrive() {
  coverage();
  last = scrollY;
  delete root.dataset.reading;
  delete root.dataset.down;
  root.toggleAttribute("data-scrolled", scrollY > 8);
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
  search();
  breaking();
  account();
}
function leave() {
  for (const stop of stopShorts) stop();
  stopShorts = [];
}
begin(arrive, leave);
arrive();
network();
