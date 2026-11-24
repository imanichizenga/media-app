// Writes spec/vectors.json from the TypeScript port. Run only when the rules change on purpose.

import { createHash } from "node:crypto";
import { writeFileSync } from "node:fs";
import { derive, failures, nearest, oklch, paint, SCHEMES, stylesheet, THEMES } from "../src/theme.ts";

// Fixed seed: the same colours every time.
let seed = 20261124;
const next = () => {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return seed;
};
const random = () => `#${(next() >>> 8).toString(16).padStart(6, "0")}`;
const chosen = [
  "#b5121b",
  "#c8102e",
  "#8b0000",
  "#e30613",
  "#0b5cad",
  "#1a6b3c",
  "#ffcc00",
  "#000000",
  "#ffffff",
  "#777777",
];
const colors = [...chosen, ...Array.from({ length: 70 }, random)];
const digest = (tokens) =>
  Object.values(tokens)
    .map((v) => v.slice(1))
    .join("");
const order = Object.keys(derive("signature", "light", "#b5121b"));
const cases = colors.map((color, i) => {
  const dark = i % 3 === 2 ? colors[(i * 7) % colors.length] : "";
  return {
    color,
    dark,
    tokens: THEMES.flatMap((t) => SCHEMES.map((s) => digest(derive(t, s, color, dark)))),
    failures: failures(color, dark).length,
    ...(i < 24 ? { nearest: nearest(color) } : {}),
    ...(i % 15 === 2 ? { nearest_dark: nearest("#b5121b", dark, "dark") } : {}),
  };
});
const paints = Array.from({ length: 300 }, () => {
  const from = oklch(random());
  const l = (next() % 1001) / 1000;
  return { from: [from.l, from.c, from.x, from.y].map((v) => Number(v.toFixed(6))), l, hex: "" };
}).map((p) => ({ ...p, hex: paint(p.l, ...p.from.slice(1)) }));
const css = Object.fromEntries(
  THEMES.map((t) => [
    t,
    createHash("sha256")
      .update(stylesheet(derive(t, "light", "#b5121b"), derive(t, "dark", "#b5121b")))
      .digest("hex"),
  ]),
);
const line = (rows) => rows.map((r) => `    ${JSON.stringify(r)}`).join(",\n");
writeFileSync(
  new URL("../spec/vectors.json", import.meta.url),
  `{\n  "themes": ${JSON.stringify(THEMES)},\n  "schemes": ${JSON.stringify(SCHEMES)},\n  "order": ${JSON.stringify(order)},\n  "css": ${JSON.stringify(css)},\n  "cases": [\n${line(cases)}\n  ],\n  "paints": [\n${line(paints)}\n  ]\n}\n`,
);
console.log(`${cases.length} colours, ${paints.length} paints`);
