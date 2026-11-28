/**
 * Search as one types (ADR-0049). A pause in typing asks for this page with the new words, the same document the CDN
 * keeps, and puts its results in place under the field: the field keeps its focus, its caret and the keyboard. An
 * empty field shows the searches made on this device, and brings the sections back. Without this file the form is an
 * ordinary GET form, and works the same.
 *
 * Nothing from the network becomes markup but this site's own documents, parsed inert (islands/navigate.ts).
 */

/** Given by site.ts: imported here, they would be split into a chunk that every page then loads. */
type Tools = {
  go: (url: URL) => void;
  ask: (url: URL) => Promise<{ url: URL; html: Document }>;
  remember: (key: string, value: string) => void;
  /** What a page does when it arrives (saved marks, lines of meta), for the results put in place. */
  fresh: () => void;
};
let tools: Tools;

const RECENT = "searches";
const WAIT = 300; // ms after the last key: quick enough to feel live, slow enough not to ask for every letter
const MIN = 2; // one letter finds everything and nothing
let timer: ReturnType<typeof setTimeout> | undefined;
let asking = 0;

const tidy = (q: string) => q.replace(/\s+/g, " ").trim().slice(0, 100).trim();

export function recent(): string[] {
  try {
    const list = JSON.parse(localStorage.getItem(RECENT) ?? "[]");
    return Array.isArray(list) ? list.filter((q) => typeof q === "string" && q.length > 0).slice(0, 8) : [];
  } catch {
    return [];
  }
}
function rememberSearch(q: string) {
  const words = tidy(q);
  if (words.length < MIN) return;
  const list = [words, ...recent().filter((x) => x.toLowerCase() !== words.toLowerCase())].slice(0, 8);
  tools.remember(RECENT, JSON.stringify(list));
}

function parts(form: HTMLFormElement) {
  const input = form.querySelector<HTMLInputElement>("input[name=q]");
  const list = form.querySelector<HTMLElement>("[role=listbox]");
  const panel = form.querySelector<HTMLElement>("[data-suggest-panel]");
  const head = form.querySelector<HTMLElement>("[data-recent-head]");
  const clear = form.querySelector<HTMLButtonElement>("[data-search-clear]");
  return input && list && panel ? { form, input, list, panel, head, clear } : null;
}
type Parts = NonNullable<ReturnType<typeof parts>>;

// ---- the searches made on this device ----
function close(p: Parts) {
  p.panel.hidden = true;
  p.list.replaceChildren();
  p.input.setAttribute("aria-expanded", "false");
  p.input.removeAttribute("aria-activedescendant");
}
function option(id: string, text: string): HTMLElement {
  const el = document.createElement("div");
  el.id = id;
  el.setAttribute("role", "option");
  el.setAttribute("aria-selected", "false");
  el.className =
    "tap flex cursor-pointer items-center px-4 aria-selected:bg-surface-sunken hover:bg-surface-sunken";
  el.dataset.words = text;
  el.textContent = text;
  return el;
}
function showRecent(p: Parts) {
  const items = recent().map((q, i) => option(`${p.list.id}-r${i}`, q));
  if (items.length === 0) return close(p);
  if (p.head) p.head.hidden = false;
  p.list.replaceChildren(...items);
  p.panel.hidden = false;
  p.input.setAttribute("aria-expanded", "true");
  p.input.removeAttribute("aria-activedescendant");
}
function move({ input, list, panel }: Parts, by: number) {
  const items = [...list.querySelectorAll<HTMLElement>("[role=option]")];
  if (panel.hidden || items.length === 0) return false;
  const now = items.findIndex((el) => el.getAttribute("aria-selected") === "true");
  // Places -1 (the field itself) to n-1, round and round.
  const next = ((now + 1 + by + items.length + 1) % (items.length + 1)) - 1;
  for (const [i, el] of items.entries()) el.setAttribute("aria-selected", String(i === next));
  const on = items[next];
  if (!on) input.removeAttribute("aria-activedescendant");
  else {
    input.setAttribute("aria-activedescendant", on.id);
    on.scrollIntoView({ block: "nearest" });
  }
  return true;
}

// ---- the words in the headlines ----
const fold = (text: string) => text.toLowerCase().normalize("NFD").replace(/\p{M}/gu, "");
/** The searched words, marked where a headline's words begin with them: one sees at once why each came. */
export function highlight() {
  const q = new URL(location.href).searchParams.get("q") ?? "";
  const words = fold(q)
    .split(/[^\p{L}\p{N}]+/u)
    .filter((w) => w.length >= 2);
  if (words.length === 0) return;
  for (const link of document.querySelectorAll<HTMLElement>("[data-results] [data-card] :is(h2, h3) a")) {
    if (link.dataset.marked !== undefined) continue;
    link.dataset.marked = "";
    for (const node of [...link.childNodes]) {
      if (node.nodeType !== Node.TEXT_NODE || !node.textContent) continue;
      const text = node.textContent;
      const parts = document.createDocumentFragment();
      let at = 0;
      for (const m of text.matchAll(/[\p{L}\p{N}]+/gu)) {
        if (!words.some((w) => fold(m[0]).startsWith(w))) continue;
        parts.append(text.slice(at, m.index));
        const mark = document.createElement("mark");
        mark.className = "hit";
        mark.textContent = m[0];
        parts.append(mark);
        at = (m.index ?? 0) + m[0].length;
      }
      if (at === 0) continue;
      parts.append(text.slice(at));
      node.replaceWith(parts);
    }
  }
}

// ---- results as one types ----
/** This page's address for the field's words and the filters the form carries; no words: the sections. */
function addressOf(form: HTMLFormElement): URL {
  const url = new URL(form.action, location.href);
  const q = tidy(form.querySelector<HTMLInputElement>("input[name=q]")?.value ?? "");
  if (q)
    for (const [k, v] of new FormData(form))
      if (typeof v === "string" && v) url.searchParams.set(k, k === "q" ? q : v);
  return url;
}
function busy(p: Parts, on: boolean) {
  p.form.setAttribute("aria-busy", String(on));
  const body = document.querySelector("[data-search-body]");
  if (on) body?.setAttribute("aria-busy", "true");
  else body?.removeAttribute("aria-busy");
}
async function run(p: Parts) {
  clearTimeout(timer);
  const url = addressOf(p.form);
  if (url.pathname + url.search === location.pathname + location.search) return;
  const mine = ++asking;
  busy(p, true);
  try {
    const got = await tools.ask(url);
    if (mine !== asking) return; // the reader has typed on: a newer answer is coming
    const next = got.html.querySelector("[data-search-body]");
    const now = document.querySelector("[data-search-body]");
    if (!next || !now) return tools.go(url);
    now.replaceWith(document.importNode(next, true));
    document.title = got.html.title;
    // The first words make a step one can go back from; the words after it change that step.
    const fromSections = !new URL(location.href).searchParams.has("q");
    if (fromSections) history.pushState(null, "", url);
    else history.replaceState(null, "", url);
    // Said to those who listen: how many came, or that none did; nothing when the sections come back.
    const status = p.form.querySelector("[data-search-status]");
    if (status) status.textContent = document.querySelector("[data-results] h2")?.textContent ?? "";
    tools.fresh();
    highlight();
  } catch {
    // The network or the site failed: the reader can still press Search, which is an ordinary request.
  } finally {
    if (mine === asking) busy(p, false);
  }
}
function typed(p: Parts) {
  if (p.clear) p.clear.hidden = p.input.value === "";
  clearTimeout(timer);
  const q = tidy(p.input.value);
  if (q.length === 0) {
    showRecent(p);
    run(p); // straight back to the sections
    return;
  }
  close(p);
  if (q.length < MIN) return;
  timer = setTimeout(() => run(p), WAIT);
}

/** Once: everything is delegated, so it holds for the forms of pages that come later. */
export function searchAsOneTypes(given: Tools) {
  tools = given;
  highlight();
  const formOf = (e: Event) => (e.target as Element | null)?.closest?.<HTMLFormElement>("form[data-search]");
  const field = (e: Event) => {
    const form = formOf(e);
    const p = form && parts(form);
    return p && e.target === p.input ? p : null;
  };
  document.addEventListener("input", (e) => {
    const p = field(e);
    if (p) typed(p);
  });
  document.addEventListener("focusin", (e) => {
    const p = field(e);
    if (p && p.input.value === "") showRecent(p);
  });
  document.addEventListener("focusout", (e) => {
    const form = formOf(e);
    const p = form && parts(form);
    // A tap on an option moves focus first: it is let through. And when the timer comes, focus may have come back
    // (Search pressed, then Clear at once): then the panel just opened stays.
    if (p && !form.contains(e.relatedTarget as Node | null))
      setTimeout(() => form.contains(document.activeElement) || close(p), 150);
  });
  document.addEventListener("keydown", (e) => {
    const p = field(e);
    if (!p) return;
    if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      if (move(p, e.key === "ArrowDown" ? 1 : -1)) e.preventDefault();
    } else if (e.key === "Escape" && !p.panel.hidden) {
      e.preventDefault();
      close(p);
    } else if (e.key === "Enter") {
      const id = p.input.getAttribute("aria-activedescendant");
      const chosen = id ? document.getElementById(id) : null;
      if (chosen?.dataset.words) {
        e.preventDefault();
        p.input.value = chosen.dataset.words;
        close(p);
        if (p.clear) p.clear.hidden = false;
        run(p);
      }
    }
  });
  document.addEventListener("click", (e) => {
    const target = e.target as Element | null;
    // A result opened: its words were worth keeping.
    if (target?.closest("[data-results] a")) {
      const q = new URL(location.href).searchParams.get("q");
      if (q) rememberSearch(q);
      return;
    }
    const form = formOf(e);
    const p = form && parts(form);
    if (!p || !target) return;
    if (target.closest("[data-search-clear]")) {
      p.input.value = "";
      p.input.focus();
      typed(p);
    } else if (target.closest("[data-search-forget]")) {
      tools.remember(RECENT, "");
      close(p);
      p.input.focus();
    } else {
      const chosen = target.closest<HTMLElement>("[role=option]");
      if (chosen?.dataset.words) {
        p.input.value = chosen.dataset.words;
        close(p);
        if (p.clear) p.clear.hidden = false;
        run(p);
      }
    }
  });
  document.addEventListener("submit", (e) => {
    const form = formOf(e);
    const p = form && parts(form);
    if (!p || e.defaultPrevented) return;
    e.preventDefault();
    close(p);
    rememberSearch(p.input.value);
    // Searched on purpose: the keyboard goes, and the results have the screen.
    p.input.blur();
    run(p);
  });
}
