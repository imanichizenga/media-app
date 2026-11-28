/**
 * Readers' accounts and engagement on the website (ADR-0050): who is signed in, the sign-in sheet, likes, comments,
 * views and readers. The tokens never reach this script: they live in httpOnly cookies, and every call goes to this
 * site's own server (app/api), which asks the API. Fetched only on pages that have something of this kind.
 *
 * Nothing from the network becomes markup: names and comments are text, put in by textContent.
 */

type Tools = {
  go: (url: URL) => void;
  toast: (text: string) => void;
  bounce: (el: Element) => void;
  remember: (key: string, value: string) => void;
  kept: () => { path: string; post?: string }[];
};
type Me = {
  id: string;
  display_name: string;
  username: string;
  initial: string;
  phone: string;
  email: string;
  onboarding: boolean;
  hide_from_readers: boolean;
  bio?: string;
  contact_email?: string;
  joined?: string;
};
type State = {
  likes: number;
  comments: number;
  bookmarks: number;
  views: number;
  readers: number;
  liked: boolean;
  /** What the story allows now: a count it does not allow is never shown on its card. */
  likes_on?: boolean;
  comments_on?: boolean;
};
type Comment = {
  id: string;
  body: string;
  created_at: string;
  author: { name: string; username: string; initial: string; is_writer: boolean };
  like_count: number;
  reply_count: number;
  liked: boolean;
  mine: boolean;
  held: boolean;
  parent: string | null;
};
type Pending =
  | { kind: "like"; post: string }
  | { kind: "comment"; post: string; body: string; parent: string | null }
  | { kind: "none" };

let tools: Tools;
let me: Me | null = null;
let known = false;
let pending: Pending = { kind: "none" };
const root = document.documentElement;
const $ = <E extends Element = HTMLElement>(s: string, from: ParentNode = document) =>
  from.querySelector<E>(s);
const $$ = <E extends Element = HTMLElement>(s: string, from: ParentNode = document) => [
  ...from.querySelectorAll<E>(s),
];
const say = (el: Element | null | undefined, key: string, value: string | number = "") =>
  ((el as HTMLElement | null)?.dataset[key] ?? "").replace("#", String(value));

// ---- talking to this site's server ----
async function call<R = unknown>(
  path: string,
  method = "GET",
  body?: unknown,
): Promise<{ status: number; data: R }> {
  const res = await fetch(path, {
    method,
    credentials: "same-origin",
    headers: body === undefined ? {} : { "content-type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = res.status === 204 ? null : await res.json().catch(() => null);
  return { status: res.status, data: data as R };
}
const signedCookie = () => /(?:^|; )signed=1/.test(document.cookie);

/** The guest's own random id, so readers are counted once whatever they open; never anything about them. */
function device(): string {
  try {
    let id = localStorage.getItem("device") ?? "";
    if (!/^[A-Za-z0-9_-]{16,64}$/.test(id)) {
      const bytes = crypto.getRandomValues(new Uint8Array(18));
      id = btoa(String.fromCharCode(...bytes)).replace(
        /[+/=]/g,
        (c) => ({ "+": "-", "/": "_", "=": "" })[c] ?? "",
      );
      tools.remember("device", id);
    }
    return id;
  } catch {
    return "";
  }
}

/** 1.3K, 12K, 3.4M: the same letters in both languages, as the app (ADR-0034). */
export function compact(n: number): string {
  if (n < 1000) return String(n);
  if (n < 1_000_000) return `${(n / 1000).toFixed(n < 10_000 ? 1 : 0).replace(/\.0$/, "")}K`;
  return `${(n / 1_000_000).toFixed(n < 10_000_000 ? 1 : 0).replace(/\.0$/, "")}M`;
}

// ---- who is signed in ----
async function whoAmI(force = false) {
  if (known && !force) return paintMe();
  known = true;
  me = null;
  if (signedCookie()) {
    const { status, data } = await call<Me>("/api/me");
    if (status === 200 && data) me = data;
  }
  paintMe();
}
function paintMe() {
  for (const el of $$("[data-me-initial]")) el.textContent = me?.initial ?? "?";
  for (const el of $$("[data-me-badge]")) el.hidden = !me;
  for (const el of $$("[data-reader-only]")) el.hidden = !me;
  const card = $("[data-account]");
  if (card) {
    ($("[data-guest]", card) as HTMLElement).hidden = Boolean(me);
    ($("[data-reader]", card) as HTMLElement).hidden = !me;
    if (me) {
      const set = (s: string, v: string) => {
        const el = $(s, card);
        if (el) el.textContent = v;
      };
      set("[data-me-name]", me.display_name || me.username);
      set("[data-me-handle]", me.username ? `@${me.username}` : "");
      set("[data-me-bio]", me.bio ?? "");
      const add = $("[data-me-add-bio]", card);
      if (add) add.hidden = Boolean(me.bio);
      const since = $("[data-me-since]", card);
      if (since && me.joined) {
        const when = new Intl.DateTimeFormat(document.documentElement.lang === "en" ? "en-GB" : "sw", {
          month: "long",
          year: "numeric",
        }).format(new Date(me.joined));
        since.textContent = say(since, "say", when);
      }
      const fill = (id: string, value: string) => {
        const el = $<HTMLInputElement | HTMLTextAreaElement>(id, card);
        if (el && document.activeElement !== el) el.value = value;
      };
      fill("#me-name", me.display_name);
      fill("#me-username", me.username);
      fill("#me-bio", me.bio ?? "");
      fill("#me-email", me.contact_email ?? "");
      count();
      const hide = $<HTMLInputElement>("[data-hide-readers]", card);
      if (hide) hide.checked = me.hide_from_readers;
    }
  }
}

/** How much of the bio is left. */
function count() {
  const bio = $<HTMLTextAreaElement>("#me-bio");
  const shown = $("[data-bio-count]");
  if (bio && shown) shown.textContent = `${bio.value.length}/160`;
}

// ---- the sign-in sheet ----
const sheet = () => $<HTMLDialogElement>("[data-auth-sheet]");
let challenge = "";
let phone = "";
let resendTimer: ReturnType<typeof setInterval> | undefined;

function step(name: "start" | "code" | "name") {
  const d = sheet();
  if (!d) return;
  for (const el of $$("[data-step]", d)) el.hidden = el.dataset.step !== name;
  error("");
  const first = $<HTMLInputElement>(`[data-step="${name}"] input`, d);
  first?.focus();
}
function error(text: string) {
  const el = $("[data-auth-error]", sheet() ?? document);
  if (el) el.textContent = text;
}
export function openSheet(intent: string, then: Pending = { kind: "none" }) {
  const d = sheet();
  if (!d) return;
  pending = then;
  try {
    sessionStorage.setItem("intent", JSON.stringify(then));
  } catch {}
  const title = $("[data-auth-title]", d);
  if (title) title.textContent = intent || title.dataset.default || "";
  // Google and Apple come back to this very page, which then finishes what was asked.
  for (const a of $$<HTMLAnchorElement>("[data-oauth]", d)) {
    const url = new URL(a.href, location.href);
    url.searchParams.set("next", location.pathname + location.search);
    a.href = url.pathname + url.search;
  }
  if (!d.open) d.showModal();
  step("start");
}
function closeSheets() {
  for (const d of $$<HTMLDialogElement>("dialog.sheet[open]")) d.close();
}
function sayError(d: HTMLElement, code: string, extra: Record<string, unknown> = {}) {
  const key =
    {
      invalid_phone: "sayPhone",
      country_not_allowed: "sayCountry",
      rate_limited: "sayWait",
      code_wrong: "sayWrong",
      code_expired: "sayExpired",
      code_locked: "sayExpired",
      sms_failed: "saySms",
      sms_not_configured: "saySms",
    }[code] ?? "sayError";
  error(say(d, key, String(extra.attempts_left ?? "")));
}
function countdown(d: HTMLElement, seconds: number) {
  const button = $<HTMLButtonElement>("[data-resend]", d);
  if (!button) return;
  const label = button.dataset.label ?? button.textContent ?? "";
  button.dataset.label = label;
  let left = seconds;
  clearInterval(resendTimer);
  const tick = () => {
    button.disabled = left > 0;
    button.textContent = left > 0 ? say(d, "sayResendIn", left) : label;
    if (left-- <= 0) clearInterval(resendTimer);
  };
  tick();
  resendTimer = setInterval(tick, 1000);
}
async function sendCode(d: HTMLElement) {
  const { status, data } = await call<{
    challenge: string;
    phone: string;
    resend_in: number;
    local_code?: string;
    code?: string;
  }>("/api/auth/code", "POST", { phone, locale: root.lang });
  if (status !== 201) return sayError(d, data?.code ?? "", data as Record<string, unknown>);
  challenge = data.challenge;
  step("code");
  const lead = $("[data-code-lead]", d);
  if (lead)
    lead.textContent = say(
      d,
      "sayLead",
      data.phone.replace(/^(\+\d{3})(\d{3})\d{3}(\d{3})$/, "$1 $2 ••• $3"),
    );
  const local = $("[data-local-code]", d);
  if (local) {
    local.hidden = !data.local_code;
    local.textContent = data.local_code ? say(d, "sayLocal", data.local_code) : "";
  }
  countdown(d, data.resend_in);
}
async function signedIn(user: Me) {
  me = user;
  known = true;
  paintMe();
  if (user.onboarding) {
    const name = $<HTMLInputElement>("#auth-name");
    if (name) name.value = user.display_name;
    return step("name");
  }
  done();
}
async function done() {
  const d = sheet();
  if (d?.open) d.close();
  tools.toast(say(d, "sayWelcome", me?.display_name || me?.username || ""));
  await mergeSaved();
  await resume();
  arrive();
}
/** What the reader was doing before signing in, done now (SPEC: intent resume). */
async function resume() {
  const then = pending;
  pending = { kind: "none" };
  try {
    sessionStorage.removeItem("intent");
  } catch {}
  if (then.kind === "like") {
    const b = $<HTMLButtonElement>(`[data-like="${then.post}"]`);
    if (b && b.getAttribute("aria-pressed") !== "true") await like(b);
  } else if (then.kind === "comment" && then.body) {
    await postComment(then.post, then.body, then.parent);
  }
}
/** Stories saved on this device before signing in go to the account, so they are on every device. */
async function mergeSaved() {
  const posts = tools
    .kept()
    .flatMap((k) => (k.post ? [k.post] : []))
    .slice(0, 50);
  await Promise.all(posts.map((p) => call(`/api/engage/posts/${p}/bookmark`, "PUT").catch(() => null)));
}

// ---- counts: views on cards, the story's own counts ----
const counts = new Map<string, State>();
async function stateOf(ids: string[]) {
  const wanted = [...new Set(ids)].filter((id) => /^[0-9a-f-]{36}$/.test(id) && !counts.has(id));
  for (let i = 0; i < wanted.length; i += 50) {
    const { status, data } = await call<Record<string, State>>(
      `/api/engage/state?posts=${wanted.slice(i, i + 50).join(",")}`,
    );
    if (status === 200 && data) for (const [id, s] of Object.entries(data)) counts.set(id, s);
  }
}
function paintCounts() {
  // On cards, before a story is opened: what the story allows, and only once someone did it.
  for (const line of $$("[data-counts]")) {
    const s = counts.get(line.dataset.counts ?? "");
    if (!s) continue;
    let any = false;
    for (const what of ["views", "likes", "comments"] as const) {
      const one = $(`[data-c="${what}"]`, line);
      if (!one) continue;
      const allowed = what === "views" || (what === "likes" ? s.likes_on : s.comments_on) !== false;
      const n = s[what];
      one.hidden = !allowed || n === 0;
      if (one.hidden) continue;
      any = true;
      const shown = $("[data-n]", one);
      if (shown) shown.textContent = compact(n);
      const said = $("[data-said]", one);
      if (said) said.textContent = say(one, "say", n);
    }
    line.hidden = !any;
  }
  for (const stats of $$("[data-stats]")) {
    const s = counts.get(stats.dataset.stats ?? "");
    if (!s) continue;
    for (const what of ["views", "readers"] as const) {
      const el = $(`[data-n="${what}"]`, stats);
      if (el) el.textContent = compact(s[what]);
      const holder = el?.parentElement;
      const said = holder && $("[data-said]", holder);
      if (said) said.textContent = say(holder, "say", s[what]);
    }
  }
  for (const b of $$<HTMLButtonElement>("[data-like]")) {
    const s = counts.get(b.dataset.like ?? "");
    if (!s) continue;
    b.setAttribute("aria-pressed", String(s.liked));
    const n = $('[data-n="likes"]', b);
    if (n) n.textContent = s.likes ? compact(s.likes) : "";
    b.setAttribute("aria-label", say(b, "say", s.likes));
  }
  const story = $("[data-comments]")?.dataset.comments;
  const s = story ? counts.get(story) : undefined;
  if (s) for (const el of $$('[data-n="comments"]')) el.textContent = s.comments ? compact(s.comments) : "";
}

async function like(b: HTMLButtonElement) {
  const post = b.dataset.like ?? "";
  if (!me) return openSheet(b.dataset.intent ?? "", { kind: "like", post });
  const s = counts.get(post) ?? { likes: 0, comments: 0, bookmarks: 0, views: 0, readers: 0, liked: false };
  const on = !s.liked;
  // Optimistic: the heart beats at once, and goes back if the server says no.
  counts.set(post, { ...s, liked: on, likes: Math.max(0, s.likes + (on ? 1 : -1)) });
  paintCounts();
  if (on) tools.bounce(b);
  const { status, data } = await call<State>(`/api/engage/posts/${post}/like`, on ? "PUT" : "DELETE");
  if (status === 200 && data) counts.set(post, { ...counts.get(post), ...data } as State);
  else {
    counts.set(post, s);
    if (status === 401) {
      me = null;
      paintMe();
      return openSheet(b.dataset.intent ?? "", { kind: "like", post });
    }
  }
  paintCounts();
}

// ---- who read it ----
async function readers(post: string) {
  const d = $<HTMLDialogElement>("[data-readers-sheet]");
  if (!d) return;
  const list = $("[data-readers-list]", d);
  const sum = $("[data-readers-sum]", d);
  const row = $<HTMLTemplateElement>("template[data-reader-row]", d)?.content.firstElementChild;
  if (!list || !sum || !row) return;
  list.replaceChildren();
  sum.textContent = "";
  d.showModal();
  const { status, data } = await call<{
    guests: number;
    results: { name: string; username: string; initial: string }[];
  }>(`/api/engage/posts/${post}/readers`);
  if (status !== 200 || !data) return;
  sum.textContent = data.results.length
    ? data.guests
      ? say(d, "sayGuests", compact(data.guests))
      : ""
    : say(d, "sayNone");
  list.replaceChildren(
    ...data.results.map((r) => {
      const li = row.cloneNode(true) as HTMLElement;
      ($("[data-initial]", li) as HTMLElement).textContent = r.initial;
      ($("[data-name]", li) as HTMLElement).textContent = r.name;
      ($("[data-handle]", li) as HTMLElement).textContent = r.username ? `@${r.username}` : "";
      return li;
    }),
  );
}

// ---- comments ----
let cursor: string | null = null;
let replyTo: string | null = null;
const box = () => $("[data-comments]");
const rel = (iso: string) => {
  const mins = Math.round((Date.now() - Date.parse(iso)) / 60_000);
  const fmt = new Intl.RelativeTimeFormat(root.lang === "en" ? "en" : "sw", { style: "short" });
  if (mins < 60) return fmt.format(-Math.max(1, mins), "minute");
  if (mins < 1440) return fmt.format(-Math.round(mins / 60), "hour");
  return fmt.format(-Math.round(mins / 1440), "day");
};
function drawComment(c: Comment, fresh = false): HTMLElement | null {
  const section = box();
  const row = $<HTMLTemplateElement>("template[data-comment-row]", section ?? document)?.content
    .firstElementChild;
  if (!section || !row) return null;
  const li = row.cloneNode(true) as HTMLElement;
  li.dataset.id = c.id;
  if (fresh) li.classList.add("fresh");
  const text = (s: string, v: string) => {
    const el = $(s, li);
    if (el) el.textContent = v;
  };
  text("[data-initial]", c.author.initial);
  text("[data-name]", c.author.name || `@${c.author.username}`);
  text("[data-body]", c.body);
  text("[data-when]", rel(c.created_at));
  $("[data-when]", li)?.setAttribute("datetime", c.created_at);
  ($("[data-writer]", li) as HTMLElement).hidden = !c.author.is_writer;
  ($("[data-held]", li) as HTMLElement).hidden = !c.held;
  ($("[data-comment-delete]", li) as HTMLElement).hidden = !c.mine;
  const heart = $("[data-comment-like]", li) as HTMLElement;
  heart.setAttribute("aria-pressed", String(c.liked));
  text("[data-likes]", c.like_count ? compact(c.like_count) : "");
  heart.dataset.count = String(c.like_count);
  if (c.parent) {
    $("[data-comment-replies]", li)?.remove();
    $("[data-replies]", li)?.remove();
  } else {
    const more = $("[data-comment-replies]", li) as HTMLElement;
    more.hidden = c.reply_count === 0;
    more.textContent = say(section, "sayReplies", c.reply_count);
  }
  return li;
}
async function loadComments(more = false) {
  const section = box();
  if (!section) return;
  const post = section.dataset.comments ?? "";
  const list = $("[data-comment-list]", section);
  const { status, data } = await call<{ results: Comment[]; next_cursor: string | null; count: number }>(
    `/api/engage/posts/${post}/comments${more && cursor ? `?cursor=${encodeURIComponent(cursor)}` : ""}`,
  );
  if (status !== 200 || !data || !list) return;
  const items = data.results.map((c) => drawComment(c)).filter((x): x is HTMLElement => x !== null);
  if (more) list.append(...items);
  else list.replaceChildren(...items);
  cursor = data.next_cursor;
  ($("[data-comments-more]", section) as HTMLElement).hidden = !cursor;
  ($("[data-comments-none]", section) as HTMLElement).hidden = list.children.length > 0;
}
async function postComment(post: string, body: string, parent: string | null) {
  const section = box();
  const { status, data } = await call<Comment & { code?: string }>(
    `/api/engage/posts/${post}/comments`,
    "POST",
    {
      body,
      parent,
    },
  );
  if (status === 201 && data) {
    const li = drawComment(data, true);
    if (!li || !section) return;
    if (data.parent) {
      const host = $(`li[data-id="${data.parent}"] [data-replies]`, section);
      host?.append(li);
    } else $("[data-comment-list]", section)?.prepend(li);
    ($("[data-comments-none]", section) as HTMLElement).hidden = true;
    const s = counts.get(post);
    if (s && !data.held) counts.set(post, { ...s, comments: s.comments + 1 });
    paintCounts();
    const area = $<HTMLTextAreaElement>("#comment-body");
    if (area) area.value = "";
    cancelReply();
    li.scrollIntoView({ block: "nearest", behavior: "smooth" });
    return;
  }
  if (status === 401) {
    me = null;
    paintMe();
    return openSheet(section?.dataset.intent ?? "", { kind: "comment", post, body, parent });
  }
  tools.toast(say(section, status === 429 ? "saySlow" : "sayFailed"));
}
function cancelReply() {
  replyTo = null;
  const bar = $("[data-replying]");
  if (bar) bar.hidden = true;
}

// ---- each page ----
let watching: IntersectionObserver | undefined;
let opened = "";
export async function arrive() {
  closeSheets();
  cursor = null;
  cancelReply();
  await whoAmI();
  const story = $("[data-stats]")?.dataset.stats;
  if (story && opened !== story + location.pathname) {
    opened = story + location.pathname;
    const { status, data } = await call<State>(`/api/engage/posts/${story}/opened`, "POST", {
      device: device(),
    });
    if (status === 200 && data) counts.set(story, data);
  }
  await stateOf([
    ...$$("[data-counts]").map((el) => el.dataset.counts ?? ""),
    ...$$("[data-like]").map((el) => el.dataset.like ?? ""),
  ]);
  paintCounts();
  watching?.disconnect();
  const section = box();
  if (section) {
    watching = new IntersectionObserver(
      (seen) => {
        if (seen.some((e) => e.isIntersecting)) {
          watching?.disconnect();
          loadComments();
        }
      },
      { rootMargin: "600px" },
    );
    watching.observe(section);
  }
  const hash = location.hash;
  if (hash === "#signed-in" || hash === "#sign-in-failed") {
    history.replaceState(history.state, "", location.pathname + location.search);
    if (hash === "#signed-in") {
      try {
        pending = JSON.parse(sessionStorage.getItem("intent") ?? '{"kind":"none"}') as Pending;
      } catch {}
      await whoAmI(true);
      if (me?.onboarding) {
        sheet()?.showModal();
        $<HTMLInputElement>("#auth-name")?.setAttribute("value", me.display_name);
        step("name");
      } else if (me) await done();
    }
  }
}

/** Once: delegated, so it holds for the pages that come later. */
export function start(given: Tools) {
  tools = given;
  addEventListener("kept", (e) => {
    const { post, on } = (e as CustomEvent<{ post?: string; on: boolean }>).detail;
    if (me && post) call(`/api/engage/posts/${post}/bookmark`, on ? "PUT" : "DELETE").catch(() => {});
  });
  document.addEventListener("click", async (e) => {
    const target = e.target as Element | null;
    if (!target) return;
    const likeButton = target.closest<HTMLButtonElement>("[data-like]");
    if (likeButton) return like(likeButton);
    const opener = target.closest<HTMLElement>("[data-auth-open]");
    if (opener) return openSheet(opener.dataset.intent ?? "");
    const who = target.closest<HTMLElement>("[data-do-readers]");
    if (who) return readers(who.dataset.doReaders ?? "");
    if (target.closest("[data-sheet-close]")) return closeSheets();
    if (target instanceof HTMLDialogElement && target.classList.contains("sheet")) return target.close(); // backdrop
    if (target.closest("[data-change-phone]")) return step("start");
    if (target.closest("[data-resend]")) return sendCode(sheet() as HTMLElement);
    if (target.closest("[data-comments-more]")) return loadComments(true);
    if (target.closest("[data-cancel-reply]")) return cancelReply();
    const li = target.closest<HTMLElement>("li.comment");
    if (li) {
      const id = li.dataset.id ?? "";
      if (target.closest("[data-comment-reply]")) {
        // A reply to a reply belongs to the first comment: one level deep.
        const top = li.parentElement?.closest<HTMLElement>("li.comment") ?? li;
        replyTo = top.dataset.id ?? null;
        const bar = $("[data-replying]");
        const to = $("[data-replying-to]");
        if (bar && to) {
          bar.hidden = false;
          to.textContent = say(box(), "sayReplyTo", $("[data-name]", li)?.textContent ?? "");
        }
        $<HTMLTextAreaElement>("#comment-body")?.focus();
        return;
      }
      if (target.closest("[data-comment-like]")) {
        if (!me) return openSheet(box()?.dataset.intent ?? "");
        const heart = $("[data-comment-like]", li) as HTMLElement;
        const on = heart.getAttribute("aria-pressed") !== "true";
        const n = Number(heart.dataset.count ?? 0) + (on ? 1 : -1);
        heart.setAttribute("aria-pressed", String(on));
        heart.dataset.count = String(Math.max(0, n));
        ($("[data-likes]", heart) as HTMLElement).textContent = n > 0 ? compact(n) : "";
        if (on) tools.bounce(heart);
        await call(`/api/engage/comments/${id}/like`, on ? "PUT" : "DELETE");
        return;
      }
      if (target.closest("[data-comment-delete]")) {
        if ((await call(`/api/engage/comments/${id}`, "DELETE")).status === 204) li.remove();
        return;
      }
      const repliesButton = target.closest<HTMLElement>("[data-comment-replies]");
      if (repliesButton) {
        const post = box()?.dataset.comments ?? "";
        const { status, data } = await call<{ results: Comment[] }>(
          `/api/engage/posts/${post}/comments?parent=${id}`,
        );
        if (status === 200 && data) {
          $("[data-replies]", li)?.replaceChildren(
            ...data.results.map((c) => drawComment(c)).filter((x): x is HTMLElement => x !== null),
          );
          repliesButton.hidden = true;
        }
        return;
      }
    }
    if (target.closest("[data-sign-out]")) {
      await call("/api/auth/sign-out", "POST");
      me = null;
      paintMe();
      tools.toast(say(sheet(), "saySignedOut"));
      return;
    }
    const remove = target.closest<HTMLElement>("[data-delete-account]");
    if (remove && confirm(remove.dataset.confirm ?? "")) {
      if ((await call("/api/me", "DELETE")).status === 202) {
        me = null;
        paintMe();
      }
    }
  });
  document.addEventListener("change", (e) => {
    const box = e.target as HTMLInputElement;
    if (box.matches("[data-hide-readers]") && me)
      call("/api/me", "PATCH", { hide_from_readers: box.checked }).then(({ data }) => {
        if (data) me = data as Me;
      });
  });
  document.addEventListener("input", (e) => {
    const el = e.target as HTMLElement;
    if (el.id === "me-bio") count();
    if (el.id === "comment-body") {
      // The box grows with what is written, up to its limit.
      el.style.height = "auto";
      el.style.height = `${el.scrollHeight}px`;
    }
    if (el.id === "auth-code" && (el as HTMLInputElement).value.replace(/\D/g, "").length === 6)
      (el.closest("form") as HTMLFormElement).requestSubmit();
  });
  document.addEventListener("focusin", (e) => {
    if ((e.target as HTMLElement).id === "comment-body" && !me && known)
      openSheet(box()?.dataset.intent ?? "", { kind: "none" });
  });
  document.addEventListener("submit", async (e) => {
    const form = e.target as HTMLFormElement;
    const kind = form.dataset.form ?? (form.matches("[data-comment-form]") ? "comment" : "");
    if (!kind) return;
    e.preventDefault();
    const d = sheet() as HTMLElement;
    const busy = form.querySelector<HTMLButtonElement>("[type=submit]");
    if (busy?.disabled) return;
    if (busy) busy.disabled = true;
    try {
      if (kind === "phone") {
        phone = (form.elements.namedItem("phone") as HTMLInputElement).value;
        const local = phone.replace(/[\s()-]/g, "");
        phone = /^\+/.test(local) ? local : /^0/.test(local) ? local : `+255${local}`;
        await sendCode(d);
      } else if (kind === "code") {
        const code = (form.elements.namedItem("code") as HTMLInputElement).value;
        const { status, data } = await call<{ user: Me; code?: string }>("/api/auth/code/verify", "POST", {
          challenge,
          code,
        });
        if (status === 200 && data) await signedIn(data.user);
        else sayError(d, data?.code ?? "", data as Record<string, unknown>);
      } else if (kind === "name") {
        const name = (form.elements.namedItem("display_name") as HTMLInputElement).value;
        const ok = (form.elements.namedItem("accept_terms") as HTMLInputElement).checked;
        if (!ok)
          return error(
            (form.querySelector("label:has([name=accept_terms])") as HTMLElement).textContent ?? "",
          );
        const { status, data } = await call<Me & { code?: string }>("/api/me", "PATCH", {
          display_name: name,
          accept_terms: true,
        });
        if (status === 200 && data) {
          me = data;
          await done();
        } else sayError(d, data?.code ?? "");
      } else if (kind === "profile") {
        const value = (n: string) => (form.elements.namedItem(n) as HTMLInputElement).value.trim();
        const status_ = $("[data-profile-status]", form);
        const { status, data } = await call<Me & { code?: string; field?: string; detail?: string }>(
          "/api/me",
          "PATCH",
          {
            display_name: value("display_name"),
            username: value("username").replace(/^@/, ""),
            bio: value("bio"),
            contact_email: value("contact_email"),
          },
        );
        for (const el of form.querySelectorAll("[aria-invalid]")) el.removeAttribute("aria-invalid");
        if (status === 200 && data) {
          me = data;
          paintMe();
          if (status_) status_.textContent = "";
          tools.toast(form.dataset.saved ?? "✓");
        } else {
          const field = data?.field ? form.querySelector(`[name="${CSS.escape(data.field)}"]`) : null;
          field?.setAttribute("aria-invalid", "true");
          (field as HTMLElement | null)?.focus();
          if (status_)
            status_.textContent =
              data?.code === "username_taken"
                ? (form.dataset.taken ?? "")
                : (data?.detail ?? form.dataset.invalid ?? "");
        }
      } else if (kind === "comment") {
        const section = box();
        const body = (form.elements.namedItem("body") as HTMLTextAreaElement).value.trim();
        if (!body || !section) return;
        const post = section.dataset.comments ?? "";
        if (!me)
          return openSheet(section.dataset.intent ?? "", { kind: "comment", post, body, parent: replyTo });
        await postComment(post, body, replyTo);
      }
    } finally {
      if (busy) busy.disabled = false;
    }
  });
}
