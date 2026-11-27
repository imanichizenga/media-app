/** Coverage that goes on (live blogs): the page asks for itself again every 30 s; at the top it is replaced at once,
 * further down a button says there is more, so nothing moves under the reader. */
let newer: Document | null = null;
let started = false;
let replaceWith: (html: Document) => unknown = () => {};

export function watch(again: () => Promise<Document | null>, replace: (html: Document) => unknown) {
  replaceWith = replace;
  if (started) return;
  started = true;
  setInterval(async () => {
    const live = document.querySelectorAll<HTMLElement>("[data-live]");
    if (document.visibilityState !== "visible" || newer || live.length === 0) return;
    const at = location.href;
    const html = await again().catch(() => null);
    if (!html || location.href !== at) return;
    if (scrollY < 80) replace(html);
    else {
      newer = html;
      for (const el of live) el.hidden = false;
    }
  }, 30_000);
}
export const reset = () => {
  newer = null;
};
export function show() {
  if (newer) replaceWith(newer);
  newer = null;
}
