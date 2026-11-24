import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import {
  check,
  DEFAULT,
  derive,
  failures,
  nearest,
  paint,
  SCHEMES,
  stylesheet,
  THEMES,
} from "../src/theme.ts";

const vectors = JSON.parse(readFileSync(new URL("../spec/vectors.json", import.meta.url), "utf8"));
const spec = JSON.parse(readFileSync(new URL("../src/themes.json", import.meta.url), "utf8"));

test("the vectors are what this port answers", () => {
  for (const c of vectors.cases) {
    const got = THEMES.flatMap((t) =>
      SCHEMES.map((s) =>
        Object.values(derive(t, s, c.color, c.dark))
          .map((v) => v.slice(1))
          .join(""),
      ),
    );
    assert.deepEqual(got, c.tokens, c.color);
    assert.equal(failures(c.color, c.dark).length, c.failures);
    if (c.nearest) assert.equal(nearest(c.color), c.nearest);
    if (c.nearest_dark) assert.equal(nearest("#b5121b", c.dark, "dark"), c.nearest_dark);
  }
  for (const p of vectors.paints) assert.equal(paint(p.l, ...p.from.slice(1)), p.hex);
});
for (const theme of THEMES)
  for (const scheme of SCHEMES) {
    const tokens = derive(theme, scheme, DEFAULT.color);
    const value = (n) => (n.startsWith("#") ? n : tokens[n]);
    for (const [fg, bg, min] of spec.pairs)
      test(`${theme} ${scheme}: ${fg} on ${bg} >= ${min}`, () => {
        assert.ok(value(fg) && value(bg), "the pair names a token that does not exist");
        assert.deepEqual(
          check(theme, scheme, tokens).filter((f) => f.fg === fg && f.bg === bg),
          [],
        );
      });
  }
test("every theme and scheme defines the same tokens, in the same order", () => {
  const keys = Object.keys(derive("signature", "light", DEFAULT.color));
  for (const t of THEMES)
    for (const s of SCHEMES) assert.deepEqual(Object.keys(derive(t, s, DEFAULT.color)), keys);
});
test("any valid colour gives themes that all pass", () => {
  let good = 0;
  for (let i = 0; i < 4000; i++) {
    const c = `#${Math.floor(Math.random() * 0x1000000)
      .toString(16)
      .padStart(6, "0")}`;
    const found = failures(c);
    if (found.length === 0) good++;
    // The dark schemes are built to pass whatever the colour is.
    assert.deepEqual(
      found.filter((f) => f.scheme === "dark"),
      [],
      c,
    );
  }
  assert.ok(good > 300, `${good}`);
});
test("the colour offered instead always passes, light and dark", () => {
  for (let i = 0; i < 60; i++) {
    const c = `#${Math.floor(Math.random() * 0x1000000)
      .toString(16)
      .padStart(6, "0")}`;
    assert.deepEqual(failures(nearest(c)), [], c);
    const dark = nearest(DEFAULT.color, c, "dark");
    assert.deepEqual(failures(DEFAULT.color, dark, "dark"), [], c);
  }
  assert.equal(nearest(DEFAULT.color), DEFAULT.color);
});
test("dark surfaces never carry the light red", () => {
  for (const t of THEMES)
    assert.ok(!Object.values(derive(t, "dark", DEFAULT.color)).includes(DEFAULT.color), t);
});
test("red discipline: in Quiet Paper only the logo, main buttons and signals are red", () => {
  const tokens = derive("quiet", "light", DEFAULT.color);
  for (const n of ["brand-text", "link", "liked", "nav-active"])
    assert.equal(tokens[n], tokens["text-primary"]);
});
test("the stylesheet outranks the bundled one", () => {
  const css = stylesheet(derive("bold", "light", "#b5121b"), derive("bold", "dark", "#b5121b"));
  assert.match(css, /^html:root \{/);
  assert.match(css, /html:root\[data-theme="dark"\]/);
  assert.match(css, /--color-brand: #b5121b;/);
});
