/**
 * Breaking news, when there are several (components/breaking.tsx): they take turns every few seconds; never under
 * the pointer or the keyboard, never for those who asked for less motion, and never once paused. All are in one grid
 * cell, so turning moves nothing around them.
 */
const still = matchMedia("(prefers-reduced-motion: reduce)");
let turning: ReturnType<typeof setInterval> | undefined;
export function turns() {
  clearInterval(turning);
  const bar = document.querySelector<HTMLElement>("[data-breaking]");
  if (!bar) return;
  const slides = [...bar.querySelectorAll<HTMLElement>("[data-slide]")];
  const at = bar.querySelector("[data-breaking-at]");
  const toggle = bar.querySelector<HTMLButtonElement>("[data-breaking-pause]");
  let now = 0;
  let held = false;
  let paused = still.matches;
  const show = (i: number) => {
    now = i;
    for (const [j, el] of slides.entries()) {
      el.toggleAttribute("data-on", j === i);
      el.toggleAttribute("inert", j !== i);
      if (j === i) el.removeAttribute("aria-hidden");
      else el.setAttribute("aria-hidden", "true");
    }
    if (at) at.textContent = `${i + 1}/${slides.length}`;
  };
  const say = () => {
    bar.toggleAttribute("data-paused", paused);
    toggle?.setAttribute("aria-label", (paused ? toggle.dataset.play : toggle.dataset.pause) ?? "");
  };
  show(0);
  say();
  turning = setInterval(() => {
    if (!paused && !held && document.visibilityState === "visible") show((now + 1) % slides.length);
  }, 6000);
  bar.addEventListener("pointerenter", () => {
    held = true;
  });
  bar.addEventListener("pointerleave", () => {
    held = false;
  });
  bar.addEventListener("focusin", () => {
    held = true;
  });
  bar.addEventListener("focusout", () => {
    held = false;
  });
  toggle?.addEventListener("click", () => {
    paused = !paused;
    // Played by hand: the next one at once, so the press is seen to do something.
    if (!paused) show((now + 1) % slides.length);
    say();
  });
}
