/**
 * The bar along the top while the next page comes (inside navigation, islands/navigate.ts), in the brand's red.
 *
 * - A quick page shows nothing: the bar waits 120 ms before it appears, so it never flashes.
 * - While it waits it creeps towards 90%, slower and slower; when the page is in, it fills and fades.
 * - Another link pressed while it runs carries on with the same bar instead of starting again.
 * - A page kept for Back, put in place at once, never starts it.
 * - If the site hands over to the browser (another language, release or theme, or an error), the bar keeps creeping
 *   until the browser's own page replaces this one; returning from the back-forward cache clears it.
 * - Under reduced motion it steps without sliding (the stylesheet).
 * - It is decoration: hidden from screen readers, which hear the new page's title instead (islands/site.ts).
 */
const DELAY = 120;
const CREEP = 200;

let bar: HTMLElement | null = null;
let shown = false;
let value = 0;
let waiting = 0;
let creeping = 0;
let fading = 0;

function element(): HTMLElement {
  if (!bar) {
    bar = document.createElement("div");
    bar.id = "progress";
    bar.setAttribute("aria-hidden", "true");
    document.body.append(bar);
  }
  return bar;
}

function paint() {
  const el = element();
  el.style.transform = `scaleX(${value})`;
  el.classList.toggle("on", shown);
}

/** A page has been asked for. */
export function start(): void {
  clearTimeout(fading);
  if (shown || waiting) return; // already on its way: one bar for the whole wait
  waiting = window.setTimeout(() => {
    waiting = 0;
    shown = true;
    value = 0.08;
    paint();
    creeping = window.setInterval(() => {
      value += (0.9 - value) * 0.08;
      paint();
    }, CREEP);
  }, DELAY);
}

/** The page is in place (or nothing needs loading after all). */
export function finish(): void {
  clearTimeout(waiting);
  waiting = 0;
  clearInterval(creeping);
  if (!shown) return;
  value = 1;
  paint();
  fading = window.setTimeout(() => {
    shown = false;
    paint();
    // Back to nothing once it has faded, so the next one grows from the left.
    fading = window.setTimeout(() => {
      value = 0;
      paint();
    }, 300);
  }, 200);
}

/** Back from the back-forward cache, the page is whole: no bar left over from leaving it. */
globalThis.addEventListener?.("pageshow", (e) => {
  if ((e as PageTransitionEvent).persisted) {
    clearTimeout(waiting);
    clearInterval(creeping);
    clearTimeout(fading);
    waiting = 0;
    shown = false;
    value = 0;
    if (bar) paint();
  }
});
