import { execSync } from "node:child_process";
import { expect, it } from "vitest";
import en from "../messages/en.json";

it("names every event the API can emit", () => {
  const source = execSync("grep -rhoE 'auth_event\\(\\s*\"[a-z_]+\"' ../backend/newsplatform || true", {
    encoding: "utf8",
  });
  const kinds = [...source.matchAll(/"([a-z_]+)"/g)].map((m) => m[1] as string);
  expect(kinds.length).toBeGreaterThan(5);
  expect(kinds.filter((k) => !(k in en.events))).toEqual([]);
});
