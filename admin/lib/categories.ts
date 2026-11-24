import type { Schemas } from "@news/api-client/admin";

export type Category = Schemas["Category"];
export const categoryName = (c: Category, locale: string) =>
  (locale === "en" ? c.texts.en?.name : c.texts.sw?.name) ?? c.texts.sw?.name ?? c.texts.en?.name ?? "…";

/** Parents before their children, in display order. */
export function flatTree(rows: Category[]): Category[] {
  const children = new Map<string | null, Category[]>();
  for (const row of rows) children.set(row.parent, [...(children.get(row.parent) ?? []), row]);
  const walk = (parent: string | null): Category[] =>
    (children.get(parent) ?? []).sort((a, b) => a.position - b.position).flatMap((c) => [c, ...walk(c.id)]);
  return walk(null);
}
