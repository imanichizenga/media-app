import assert from "node:assert/strict";
import { test } from "node:test";
import { dark, light } from "../dist/tokens.js";

const lum = (hex) => {
  const [r, g, b] = [1, 3, 5]
    .map((i) => Number.parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((c) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const ratio = (a, b) => {
  const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};
const grounds = ["bg", "surface", "surface-raised", "surface-sunken"];
const text = [
  "text-primary",
  "text-secondary",
  "text-tertiary",
  "accent",
  "success",
  "warning",
  "danger",
  "live",
];
const pairs = [
  ...text.flatMap((fg) => grounds.map((bg) => [fg, bg, 4.5])),
  ...["success", "warning", "danger", "accent"].map((n) => [n, `${n}-soft`, 4.5]),
  ["on-accent", "accent", 4.5],
  ["on-danger", "danger", 4.5],
  ["on-live", "live", 4.5],
  // WCAG 1.4.11: control outlines and focus rings
  ...["border-strong", "focus"].flatMap((fg) => grounds.map((bg) => [fg, bg, 3])),
];

for (const [name, theme] of Object.entries({ light, dark })) {
  for (const [fg, bg, min] of pairs) {
    test(`${name}: ${fg} on ${bg} >= ${min}`, () => {
      const value = ratio(theme[fg], theme[bg]);
      assert.ok(value >= min, `${fg}/${bg} is ${value.toFixed(2)}:1`);
    });
  }
  test(`${name}: red is reserved for breaking and live`, () => assert.notEqual(theme.danger, theme.live));
}
test("both themes define the same tokens", () => assert.deepEqual(Object.keys(light), Object.keys(dark)));
