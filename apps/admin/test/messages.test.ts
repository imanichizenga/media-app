import { describe, expect, it } from "vitest";
import en from "../messages/en.json";
import sw from "../messages/sw.json";

const flat = (o: object, p = ""): Record<string, string> =>
  Object.entries(o).reduce(
    (all, [k, v]) => Object.assign(all, typeof v === "string" ? { [p + k]: v } : flat(v, `${p}${k}.`)),
    {},
  );
const args = (s: string) =>
  [...s.matchAll(/\{(\w+)/g)]
    .map((m) => m[1])
    .filter((n) => !/^[A-Z]/.test(n ?? ""))
    .sort();

describe("translations", () => {
  const [a, b] = [flat(en), flat(sw)];
  it("define the same keys", () => expect(Object.keys(b).sort()).toEqual(Object.keys(a).sort()));
  it("use the same variables", () => {
    for (const key of Object.keys(a))
      expect(new Set(args(b[key] ?? "")), key).toEqual(new Set(args(a[key] ?? "")));
  });
  it("leave nothing empty", () =>
    expect(Object.entries({ ...a, ...b }).filter(([, v]) => !v.trim())).toEqual([]));
});
