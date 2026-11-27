/** Stories kept in this browser, and how it likes to read. */
export type Kept = { path: string; headline: string; category: string; post?: string };
const KEY = "saved";

export function remember(key: string, value: string) {
  try {
    if (value) localStorage.setItem(key, value);
    else localStorage.removeItem(key);
  } catch {
    // A private window: it lasts as long as the page.
  }
}
export function kept(): Kept[] {
  try {
    const list = JSON.parse(localStorage.getItem(KEY) ?? "[]");
    return Array.isArray(list)
      ? list.filter((k) => typeof k?.path === "string" && /^\/(?![/\\])/.test(k.path))
      : [];
  } catch {
    return [];
  }
}
const write = (list: Kept[]) => remember(KEY, list.length > 0 ? JSON.stringify(list.slice(0, 200)) : "");
export const keep = (k: Kept) => write([k, ...kept().filter((x) => x.path !== k.path)]);
export const unkeep = (path: string) => write(kept().filter((x) => x.path !== path));
