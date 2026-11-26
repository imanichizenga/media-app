// Before first paint: the reader's own scheme and text size, so that nothing flashes. A classic script that blocks
// for the time it takes to read a few bytes from the cache, so the policy needs no inline script (ADR-0046).
try {
  const d = document.documentElement;
  const s = localStorage.getItem("scheme");
  const t = localStorage.getItem("text");
  if (s === "dark" || s === "light") d.dataset.theme = s;
  if (t && /^[1-3]$/.test(t)) d.dataset.text = t;
} catch {
  // Storage refused (private mode, a policy): the page follows the device.
}
