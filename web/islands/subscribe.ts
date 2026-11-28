/**
 * Subscriptions on the website (ADR-0052): a subscriber's story opens in place; the plans page picks a plan, asks
 * how to pay, and watches the payment until the reader's phone (or the card checkout) says yes.
 *
 * The one piece of markup taken from the network is the story's own body, drawn by this site's server from the
 * article (app/api/subscribe) exactly as the page itself draws it: never anything a reader wrote.
 */
type Account = typeof import("./account");
type Tools = { toast: (text: string) => void; account: () => Promise<Account> | null };
type Payment = {
  id: string;
  status: "pending" | "completed" | "failed" | "expired" | "voided";
  method: "mobile" | "card";
  checkout_url: string;
  subscription: { active: boolean; ends_at: string | null };
  code?: string;
  field?: string;
};

type Policy = { createHTML: (s: string) => string };
// Trusted Types (lib/csp.ts): the one HTML parsed here is the story's body from this site's own server, same origin,
// parsed inert (DOMParser runs no script) and its nodes moved in.
const trusted: Policy = (
  globalThis as unknown as {
    trustedTypes?: { createPolicy: (name: string, rules: Policy) => Policy };
  }
).trustedTypes?.createPolicy("subscriber", { createHTML: (s) => s }) ?? { createHTML: (s) => s };

let tools: Tools;
let polling = 0;
const $ = <E extends HTMLElement = HTMLElement>(s: string, root: ParentNode = document) =>
  root.querySelector<E>(s);
const $$ = <E extends HTMLElement = HTMLElement>(s: string, root: ParentNode = document) =>
  root.querySelectorAll<E>(s);
const signed = () => /(?:^|; )signed=1/.test(document.cookie);
const sheet = () => $<HTMLDialogElement>("[data-pay-sheet]");
const say = (key: string, value = "") => (sheet()?.dataset[key] ?? "").replace("#", value);
const locale = () => $("[data-plans]")?.dataset.locale ?? $("[data-paywall]")?.dataset.locale ?? "sw";

async function call<R>(
  path: string,
  method = "GET",
  body?: unknown,
): Promise<{ status: number; data: R | null }> {
  try {
    const res = await fetch(path, {
      method,
      credentials: "same-origin",
      headers: body === undefined ? {} : { "content-type": "application/json" },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { status: res.status, data: (await res.json().catch(() => null)) as R | null };
  } catch {
    return { status: 0, data: null };
  }
}

async function signIn(intent: string, then: "subscribe" | "none") {
  const account = await tools.account();
  account?.openSheet(intent, { kind: then });
}

// ---- a story for subscribers ----
async function unlock() {
  const wall = $("[data-paywall]");
  const body = $("[data-body][data-locked]");
  const signInButton = $("[data-paywall-sign-in]", wall ?? document);
  if (signInButton) signInButton.hidden = signed();
  if (!wall || !body || !signed() || wall.dataset.trying) return;
  wall.dataset.trying = "1";
  const offer = $("[data-offer]", wall);
  const busy = $("[data-unlock]", wall);
  if (offer) offer.hidden = true;
  if (busy) busy.hidden = false;
  const { status, data } = await call<{ html: string }>(
    `/api/subscribe/posts/${wall.dataset.paywall}?locale=${locale()}`,
  );
  delete wall.dataset.trying;
  if (status === 200 && data?.html) {
    const parsed = new DOMParser().parseFromString(trusted.createHTML(data.html), "text/html");
    for (const script of parsed.querySelectorAll("script")) script.remove();
    body.replaceChildren(...Array.from(parsed.body.childNodes, (n) => document.importNode(n, true)));
    body.removeAttribute("data-locked");
    body.classList.add("unlocked");
    wall.remove();
    return;
  }
  if (offer) offer.hidden = false;
  if (busy) busy.hidden = true;
}

// ---- the plans ----
function intervals() {
  const form = $<HTMLFormElement>("[data-plan-form]");
  if (!form) return;
  const chosen = $<HTMLInputElement>("input[name=interval]:checked", form)?.value ?? "month";
  for (const grid of $$("[data-interval]", form)) grid.hidden = grid.dataset.interval !== chosen;
  const grid = $(`[data-interval="${chosen}"]`, form) ?? $("[data-interval]", form);
  if (grid && !$("input[name=plan]:checked", grid)) {
    const pick =
      $<HTMLInputElement>("input[name=plan][data-pick]", grid) ??
      $<HTMLInputElement>("input[name=plan]", grid);
    if (pick) pick.checked = true;
  }
}

function step(name: string) {
  const d = sheet();
  if (!d) return;
  for (const el of $$("[data-step]", d)) el.hidden = el.dataset.step !== name;
  if (!d.open) d.showModal();
}

function methods() {
  const d = sheet();
  if (!d) return;
  const method = $<HTMLInputElement>("input[name=method]:checked", d)?.value;
  const phone = $("[data-phone]", d);
  if (phone) phone.hidden = method !== "mobile";
}

function chosen(): HTMLInputElement | null {
  return $<HTMLInputElement>("[data-plan-form] input[name=plan]:checked");
}

function openPay() {
  const d = sheet();
  const plan = chosen();
  if (!d || !plan) return;
  const title = $("[data-pay-title]", d);
  if (title) title.textContent = say("sayTitle", plan.dataset.name ?? "");
  const summary = $("[data-pay-summary]", d);
  if (summary) summary.textContent = `${plan.dataset.price ?? ""} ${plan.dataset.per ?? ""}`;
  const label = $("[data-pay-label]", d);
  if (label) label.textContent = say("sayPay", plan.dataset.price ?? "");
  const error = $("[data-pay-error]", d);
  if (error) error.hidden = true;
  methods();
  step("method");
  $<HTMLInputElement>("#pay-phone", d)?.focus();
}

function fail(text: string) {
  const d = sheet();
  if (!d) return;
  const out = $("[data-pay-failed]", d);
  if (out) out.textContent = text;
  step("failed");
}

function done(p: Payment) {
  const d = sheet();
  if (!d) return;
  const next = $("[data-plans]")?.dataset.next ?? "/";
  const until = p.subscription.ends_at
    ? new Intl.DateTimeFormat(locale() === "en" ? "en-GB" : "sw", { dateStyle: "long" }).format(
        new Date(p.subscription.ends_at),
      )
    : "";
  const text = $("[data-pay-until]", d);
  if (text) text.textContent = until ? say("sayUntil", until) : "";
  const go = $<HTMLAnchorElement>("[data-pay-continue]", d);
  if (go) go.href = next;
  step("done");
}

/** Every couple of seconds while the sheet is open, for up to five minutes: the phone's PIN takes a while. */
function watch(id: string) {
  const run = ++polling;
  const until = Date.now() + 5 * 60_000;
  const tick = async () => {
    if (run !== polling || !sheet()?.open) return;
    const { status, data } = await call<Payment>(`/api/subscribe/payments/${id}?locale=${locale()}`);
    if (run !== polling) return;
    if (status === 200 && data) {
      if (data.status === "completed") return done(data);
      if (data.status === "expired") return fail(say("sayExpired"));
      if (data.status !== "pending") return fail(say("sayFailed"));
    }
    if (Date.now() > until) return fail(say("sayExpired"));
    setTimeout(tick, 2500);
  };
  setTimeout(tick, 2000);
}

async function pay(form: HTMLFormElement) {
  const d = sheet();
  const plan = chosen();
  if (!d || !plan) return;
  const method = $<HTMLInputElement>("input[name=method]:checked", form)?.value ?? "mobile";
  const error = $("[data-pay-error]", d);
  const show = (text: string) => {
    if (error) {
      error.textContent = text;
      error.hidden = false;
    }
  };
  let phone = "";
  if (method === "mobile") {
    const raw = ($<HTMLInputElement>("#pay-phone", d)?.value ?? "").replace(/[\s()-]/g, "");
    phone = /^\+/.test(raw) ? raw : /^0/.test(raw) ? raw : raw ? `+255${raw}` : "";
    if (!/^(\+255|0)[67]\d{8}$/.test(phone)) return show(say("sayPhone"));
  }
  const next = $("[data-plans]")?.dataset.next ?? "/";
  const back = `${location.pathname}?next=${encodeURIComponent(next)}`;
  const { status, data } = await call<Payment>(`/api/subscribe/checkout?locale=${locale()}`, "POST", {
    plan: plan.value,
    method,
    phone,
    return_path: back,
  });
  if (status === 401) return signIn(d.dataset.intent ?? "", "subscribe");
  if (status === 201 && data) {
    if (method === "card") {
      if (!data.checkout_url) return fail(say("sayUnavailable"));
      step("card");
      location.assign(data.checkout_url);
      return;
    }
    const wait = $("[data-pay-wait]", d);
    const shown = phone.replace(/^0/, "+255").replace(/^(\+255)(\d{3})(\d{3})(\d{3})$/, "$1 $2 $3 $4");
    if (wait) wait.textContent = say("sayWait", shown);
    step("wait");
    return watch(data.id);
  }
  if (data?.field === "phone") return show(say("sayPhone"));
  show(status === 503 || data?.code === "method_unavailable" ? say("sayUnavailable") : say("sayFailed"));
}

/** Back from the card checkout (or a pretend one, locally): watch the payment it was for. */
function returned() {
  const url = new URL(location.href);
  const id = url.searchParams.get("payment");
  if (!id || !/^[0-9a-f-]{36}$/.test(id) || !sheet()) return;
  url.searchParams.delete("payment");
  history.replaceState(history.state, "", url);
  const wait = $("[data-pay-wait]", sheet() as HTMLElement);
  if (wait) wait.textContent = "";
  step("wait");
  watch(id);
}

export function start(given: Tools) {
  tools = given;
  addEventListener("signed-in", () => void unlock());
  // After the account island has tidied its sheets away (account.ts arrive).
  addEventListener("resume-subscribe", () => setTimeout(openPay, 60));
  document.addEventListener("change", (e) => {
    const target = e.target as HTMLElement;
    if (target.matches("input[name=interval]")) intervals();
    if (target.matches("[data-pay-sheet] input[name=method]")) methods();
  });
  document.addEventListener("click", (e) => {
    const target = e.target as HTMLElement;
    const signInButton = target.closest<HTMLElement>("[data-paywall-sign-in]");
    if (signInButton) void signIn(signInButton.dataset.intent ?? "", "none");
    if (target.closest("[data-pay-again]")) openPay();
    if (target.closest("[data-pay-sheet] [data-sheet-close]")) {
      polling++;
      sheet()?.close();
    }
  });
  document.addEventListener("submit", (e) => {
    const form = e.target as HTMLFormElement;
    if (form.matches("[data-plan-form]")) {
      e.preventDefault();
      if (!signed()) return void signIn(sheet()?.dataset.intent ?? "", "subscribe");
      openPay();
    } else if (form.matches("[data-pay-form]")) {
      e.preventDefault();
      const go = $<HTMLButtonElement>("[data-pay-go]", form);
      if (go?.disabled) return;
      if (go) go.disabled = true;
      void pay(form).finally(() => {
        if (go) go.disabled = false;
      });
    }
  });
}

export function arrive() {
  intervals();
  void unlock();
  returned();
}
