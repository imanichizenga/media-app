// The site's service worker (ADR-0051): notifications of new stories, and pages that open without a network.
// Plain script, served as it is from /sw.js (scope "/"), no build step.
const CACHE = "news-v1";
const FILES = /^\/(js|_next\/static|fonts|theme)\//;

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((names) => Promise.all(names.filter((n) => n !== CACHE).map((n) => caches.delete(n))))
      .then(() => self.clients.claim()),
  );
});

function keep(request, response) {
  if (response.ok && response.type === "basic") {
    const copy = response.clone();
    caches.open(CACHE).then((cache) => cache.put(request, copy));
  }
  return response;
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin || url.pathname.startsWith("/api/")) return;
  if (request.mode === "navigate") {
    // The network first, so news is always new; the last copy of the page (or the front page) when there is none.
    event.respondWith(
      fetch(request)
        .then((response) => keep(request, response))
        .catch(async () => (await caches.match(request)) || (await caches.match("/")) || Response.error()),
    );
    return;
  }
  if (FILES.test(url.pathname)) {
    // Content-hashed and immutable: from the cache once fetched.
    event.respondWith(
      caches.match(request).then((hit) => hit || fetch(request).then((r) => keep(request, r))),
    );
  }
});

self.addEventListener("push", (event) => {
  let message = {};
  try {
    message = event.data ? event.data.json() : {};
  } catch {
    message = {};
  }
  event.waitUntil(
    self.registration.showNotification(message.title || "", {
      body: message.body || "",
      icon: "/theme/icon.svg",
      badge: "/theme/icon.svg",
      image: message.image || undefined,
      tag: message.tag || undefined,
      data: { url: message.url || "/" },
    }),
  );
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || "/", self.location.origin);
  // Only this site's own pages open from a notification.
  if (target.origin !== self.location.origin) return;
  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((open) => {
      for (const client of open) {
        if (new URL(client.url).pathname === target.pathname && "focus" in client) return client.focus();
      }
      return self.clients.openWindow(target.href);
    }),
  );
});
