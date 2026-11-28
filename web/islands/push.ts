/**
 * The site as an app (ADR-0051): the service worker, and the bell that asks to hear of every new story. Nothing is
 * asked of the browser until the reader presses the bell.
 */
type Policy = { createScriptURL: (s: string) => string };
const policy: Policy = (
  window as unknown as { trustedTypes?: { createPolicy: (name: string, rules: Policy) => Policy } }
).trustedTypes?.createPolicy("worker", {
  createScriptURL: (s) => {
    if (s !== "/sw.js") throw new TypeError("Only the site's own worker");
    return s;
  },
}) ?? { createScriptURL: (s) => s };

const supported = () => "serviceWorker" in navigator && "PushManager" in window && "Notification" in window;
let ready: Promise<ServiceWorkerRegistration> | null = null;

export function register() {
  if (!("serviceWorker" in navigator) || ready) return;
  ready = navigator.serviceWorker
    .register(policy.createScriptURL("/sw.js") as unknown as string, { scope: "/" })
    .then(() => navigator.serviceWorker.ready);
  ready.catch(() => {
    ready = null;
  });
}

const key = (text: string) => {
  const raw = atob(text.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - (text.length % 4)) % 4));
  return Uint8Array.from(raw, (c) => c.charCodeAt(0));
};

async function current(): Promise<PushSubscription | null> {
  if (!supported() || !ready) return null;
  return (await ready).pushManager.getSubscription();
}

/** The bell says whether this browser hears of new stories. */
export async function paint() {
  const on = Boolean(await current()) && Notification.permission === "granted";
  for (const b of document.querySelectorAll<HTMLButtonElement>("[data-notify]")) {
    b.setAttribute("aria-pressed", String(on));
    b.setAttribute("aria-label", (on ? b.dataset.off : b.dataset.on) ?? "");
    b.title = b.getAttribute("aria-label") ?? "";
  }
}

async function call(method: "POST" | "DELETE", body: unknown) {
  return fetch("/api/push/subscriptions", {
    method,
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

/** Pressed: on (asking the browser first), or off. Says what happened in a word at the foot. */
export async function toggle(button: HTMLButtonElement, toast: (text: string) => void) {
  const say = (k: string) => toast(button.dataset[k] ?? "");
  if (!supported()) return say("unsupported");
  register();
  const was = await current();
  if (was) {
    await call("DELETE", { endpoint: was.endpoint }).catch(() => null);
    await was.unsubscribe().catch(() => null);
    await paint();
    return say("gone");
  }
  const allowed =
    Notification.permission === "granted" || (await Notification.requestPermission()) === "granted";
  if (!allowed) return say("blocked");
  const answer = await fetch("/api/push/key")
    .then((r) => r.json() as Promise<{ enabled: boolean; public_key: string }>)
    .catch(() => null);
  if (!answer?.enabled || !ready) return say("unsupported");
  try {
    const subscription = await (await ready).pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: key(answer.public_key),
    });
    const res = await call("POST", { ...subscription.toJSON(), locale: document.documentElement.lang });
    if (!res.ok) throw new Error(String(res.status));
    say("done");
  } catch {
    say("unsupported");
  }
  await paint();
}
