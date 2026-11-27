/** How far down the page one is, for browsers that cannot tie the line under the top to the scroll (globals.css). */
const root = document.documentElement;
let drawing = 0;
addEventListener(
  "scroll",
  () => {
    cancelAnimationFrame(drawing);
    drawing = requestAnimationFrame(() => {
      const room = root.scrollHeight - innerHeight;
      root.style.setProperty("--scrolled", String(room > 0 ? Math.min(1, scrollY / room) : 0));
    });
  },
  { passive: true },
);

export {};
