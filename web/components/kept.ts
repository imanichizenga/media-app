/** Stories kept in this browser. */
export type Kept = { path: string; headline: string; category: string };
const KEY = "saved";
const EVENT = "kept";

export function kept(): Kept[] {
  try {
    const list = JSON.parse(localStorage.getItem(KEY) ?? "[]");
    return Array.isArray(list) ? list.filter((k) => typeof k?.path === "string" && k.path.startsWith("/")) : [];
  } catch {
    return [];
  }
}
function write(list: Kept[]) {
  try {
    localStorage.setItem(KEY, JSON.stringify(list.slice(0, 200)));
  } catch {
    // Full or private: nothing to be done.
  }
  dispatchEvent(new Event(EVENT));
}
export const keep = (k: Kept) => write([k, ...kept().filter((x) => x.path !== k.path)]);
export const unkeep = (path: string) => write(kept().filter((x) => x.path !== path));
export function onKept(listen: () => void) {
  addEventListener(EVENT, listen);
  addEventListener("storage", listen);
  return () => {
    removeEventListener(EVENT, listen);
    removeEventListener("storage", listen);
  };
}
