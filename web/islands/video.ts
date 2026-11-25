import type Hls from "hls.js/light";

const saving = () =>
  Boolean((navigator as Navigator & { connection?: { saveData?: boolean } }).connection?.saveData) ||
  matchMedia("(prefers-reduced-motion: reduce)").matches;

/** Adaptive HLS. Nothing is downloaded before it is wanted: not the stream, not the player. */
async function attach(el: HTMLVideoElement, source: string, failed: () => void): Promise<() => void> {
  // Safari plays it by itself.
  if (el.canPlayType("application/vnd.apple.mpegurl") && !("MediaSource" in window)) {
    el.src = source;
    return () => {
      el.removeAttribute("src");
      el.load();
    };
  }
  const { default: Player } = await import("hls.js/light");
  if (!Player.isSupported()) {
    el.src = source;
    return () => el.removeAttribute("src");
  }
  // No worker: it would need blob: scripts, which the policy refuses.
  const player: Hls = new Player({ enableWorker: false, capLevelToPlayerSize: true, maxBufferLength: 20 });
  player.on(Player.Events.ERROR, (_, data) => data.fatal && failed());
  player.loadSource(source);
  player.attachMedia(el);
  return () => player.destroy();
}

/** A player in a story: from packages/ui, by its markup. */
export async function playVideo(button: HTMLElement) {
  const box = button.closest<HTMLElement>("[data-hls]");
  const el = box?.querySelector("video");
  if (!box || !el) return;
  button.hidden = true;
  el.controls = true;
  const failed = () => {
    const said = box.querySelector<HTMLElement>("[data-failed]");
    if (said) said.hidden = false;
  };
  try {
    await attach(el, box.dataset.hls ?? "", failed);
    await el.play().catch(() => {});
    el.focus();
  } catch {
    failed();
  }
}

export function playYouTube(button: HTMLElement) {
  const id = button.dataset.youtube ?? "";
  if (!/^[\w-]{11}$/.test(id)) return;
  const frame = document.createElement("iframe");
  frame.className = button.className;
  frame.src = `https://www.youtube-nocookie.com/embed/${id}?autoplay=1&start=${Number(button.dataset.start ?? 0)}`;
  frame.title = button.getAttribute("aria-label") ?? "YouTube";
  frame.allow = "autoplay; encrypted-media; picture-in-picture; fullscreen";
  frame.referrerPolicy = "strict-origin-when-cross-origin";
  button.replaceWith(frame);
  frame.focus();
}

/** Shorts: only the one looked at plays, and only then is anything downloaded. Returns how to stop. */
export function shorts(list: HTMLElement): () => void {
  const stop = new Map<Element, () => void>();
  const halt = (li: Element) => {
    stop.get(li)?.();
    stop.delete(li);
    li.querySelector("video")?.pause();
  };
  const start = (li: HTMLElement) => {
    const el = li.querySelector("video");
    if (!el || stop.has(li)) return;
    if (el.dataset.poster) el.poster = el.dataset.poster;
    const next = li.nextElementSibling?.querySelector("video");
    if (next?.dataset.poster) next.poster = next.dataset.poster;
    let gone = false;
    let destroy = () => {};
    stop.set(li, () => {
      gone = true;
      destroy();
    });
    const failed = () => {
      const said = li.querySelector<HTMLElement>("[data-failed]");
      if (said) said.hidden = false;
    };
    const go = async () => {
      destroy = await attach(el, li.dataset.hls ?? "", failed);
      if (gone) return destroy();
      el.muted = !("sound" in document.documentElement.dataset);
      if (!("stopped" in li.dataset)) await el.play().catch(() => {});
    };
    if (saving()) li.dataset.stopped = "";
    // With the data saver on, a tap fetches it.
    if ("stopped" in li.dataset) el.addEventListener("short:play", () => go().catch(failed), { once: true });
    else go().catch(failed);
  };
  const eye = new IntersectionObserver(
    (seen) => {
      for (const e of seen)
        if (e.intersectionRatio > 0.6) start(e.target as HTMLElement);
        else halt(e.target);
    },
    { root: list, threshold: [0, 0.6, 1] },
  );
  for (const li of list.children) eye.observe(li);
  const hidden = () => {
    if (document.visibilityState === "hidden") for (const v of list.querySelectorAll("video")) v.pause();
  };
  document.addEventListener("visibilitychange", hidden);
  return () => {
    eye.disconnect();
    document.removeEventListener("visibilitychange", hidden);
    for (const li of [...stop.keys()]) halt(li);
  };
}
export function toggleShort(button: HTMLElement) {
  const li = button.closest<HTMLElement>("[data-hls]");
  const el = li?.querySelector("video");
  if (!li || !el) return;
  if (el.paused) {
    delete li.dataset.stopped;
    button.setAttribute("aria-label", button.dataset.pause ?? "");
    if (el.readyState === 0) el.dispatchEvent(new Event("short:play"));
    el.play().catch(() => {});
  } else {
    li.dataset.stopped = "";
    button.setAttribute("aria-label", button.dataset.play ?? "");
    el.pause();
  }
}
export function toggleSound() {
  const root = document.documentElement;
  const on = !("sound" in root.dataset);
  if (on) root.dataset.sound = "";
  else delete root.dataset.sound;
  for (const v of document.querySelectorAll<HTMLVideoElement>("[data-shorts] video")) v.muted = !on;
  for (const b of document.querySelectorAll<HTMLElement>('[data-do="mute"]'))
    b.setAttribute("aria-label", (on ? b.dataset.mute : b.dataset.unmute) ?? "");
}
