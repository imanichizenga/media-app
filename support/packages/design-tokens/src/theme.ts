/**
 * Brand colour → every token of every theme. The rules are spec/derivation.md; the Python and Dart ports must give
 * the same answers for spec/vectors.json, to the last digit.
 */
import spec from "./themes.json" with { type: "json" };

export type ThemeKey = keyof typeof spec.themes;
export type Scheme = "light" | "dark";
export type Tokens = Record<string, string>;
type Rule = string | (string | number)[];
export const THEMES = Object.keys(spec.themes) as ThemeKey[];
export const SCHEMES: Scheme[] = ["light", "dark"];
export const DEFAULT = { theme: spec.default as ThemeKey, color: spec.color };
export const themeName = (key: ThemeKey, locale: "sw" | "en") => spec.themes[key].name[locale];
export const themeNote = (key: ThemeKey, locale: "sw" | "en") => spec.themes[key].note[locale];

// ---- colour ----
const decode = (c: number) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
const encode = (c: number) => (c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055);
const channels = (hex: string) =>
  [1, 3, 5].map((i) => decode(Number.parseInt(hex.slice(i, i + 2), 16) / 255));
const luminance = (hex: string) => {
  const [r = 0, g = 0, b = 0] = channels(hex);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
export function contrast(a: string, b: string): number {
  const x = luminance(a);
  const y = luminance(b);
  return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
}
/** Lightness, chroma and the direction of the hue. No angles, so no trigonometry to disagree about. */
type Oklch = { l: number; c: number; x: number; y: number };
export function oklch(hex: string): Oklch {
  const [r = 0, g = 0, b = 0] = channels(hex);
  const p = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3);
  const q = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3);
  const s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3);
  const l = 0.2104542553 * p + 0.793617785 * q - 0.0040720468 * s;
  const A = 1.9779984951 * p - 2.428592205 * q + 0.4505937099 * s;
  const B = 0.0259040371 * p + 0.7827717662 * q - 0.808675766 * s;
  const c = Math.sqrt(A * A + B * B);
  return c < 0.0005 ? { l, c: 0, x: 0, y: 0 } : { l, c, x: A / c, y: B / c };
}
function linear(l: number, c: number, x: number, y: number): [number, number, number] {
  const A = c * x;
  const B = c * y;
  const p = l + 0.3963377774 * A + 0.2158037573 * B;
  const q = l - 0.1055613458 * A - 0.0638541728 * B;
  const s = l - 0.0894841775 * A - 1.291485548 * B;
  const p3 = p * p * p;
  const q3 = q * q * q;
  const s3 = s * s * s;
  return [
    4.0767416621 * p3 - 3.3077115913 * q3 + 0.2309699292 * s3,
    -1.2684380046 * p3 + 2.6097574011 * q3 - 0.3413193965 * s3,
    -0.0041960863 * p3 - 0.7034186147 * q3 + 1.707614701 * s3,
  ];
}
const inside = (rgb: number[]) => rgb.every((v) => v >= -0.0001 && v <= 1.0001);
/** The nearest colour a screen can show: lightness and hue are kept, chroma gives way. */
export function paint(l: number, c: number, x: number, y: number): string {
  let rgb = linear(l, c, x, y);
  if (!inside(rgb)) {
    let low = 0;
    let high = c;
    for (let i = 0; i < 20; i++) {
      const mid = (low + high) / 2;
      if (inside(linear(l, mid, x, y))) low = mid;
      else high = mid;
    }
    rgb = linear(l, low, x, y);
  }
  return `#${rgb
    .map((v) => Math.floor(encode(Math.min(1, Math.max(0, v))) * 255 + 0.5))
    .map((v) => v.toString(16).padStart(2, "0"))
    .join("")}`;
}

// ---- derivation ----
const passes = (hex: string, grounds: string[], min: number) => grounds.every((g) => contrast(hex, g) >= min);
export function derive(theme: ThemeKey, scheme: Scheme, color: string, darkColor = ""): Tokens {
  const source = spec.themes[theme][scheme];
  const override = scheme === "dark" && darkColor !== "";
  const base = (override ? darkColor : color).toLowerCase();
  const o = oklch(base);
  const out: Tokens = { ...source.neutral };
  const value = (name: string) => (name.startsWith("#") ? name : (out[name] as string));
  const walk = (start: number, step: number, c: number, grounds: string[], min: number) => {
    for (let i = 0; ; i++) {
      const l = start + step * i;
      const hex = paint(l, c, o.x, o.y);
      if (l >= 1 || passes(hex, grounds, min)) return hex;
    }
  };
  for (const [name, rule] of Object.entries(source.brand) as [string, Rule][]) {
    if (typeof rule === "string") {
      out[name] = rule.startsWith("@") ? value(rule.slice(1)) : rule;
      continue;
    }
    const [op, ...rest] = rule;
    const grounds = () => rest.map((r) => value(String(r)));
    if (op === "exact") out[name] = base;
    else if (op === "fill") out[name] = walk(0.3, 0.0025, o.c * 0.92, grounds(), 3);
    else if (op === "soften")
      out[name] = override ? base : walk(0.64, 0.005, Math.min(o.c * 0.9, 0.17), grounds(), 4.5);
    else if (op === "strong") {
      const from = oklch(value(String(rest[0])));
      out[name] = paint(Math.max(0, from.l - 0.055), from.c, from.x, from.y);
    } else if (op === "tint") out[name] = paint(Number(rest[0]), Math.min(o.c, Number(rest[1])), o.x, o.y);
    else throw new Error(`Unknown rule ${op}`);
  }
  return out;
}

// ---- validation ----
export type Failure = { theme: ThemeKey; scheme: Scheme; fg: string; bg: string; ratio: number; min: number };
export function check(theme: ThemeKey, scheme: Scheme, tokens: Tokens): Failure[] {
  const value = (name: string) => (name.startsWith("#") ? name : (tokens[name] as string));
  return (spec.pairs as [string, string, number][])
    .map(([fg, bg, min]) => ({ theme, scheme, fg, bg, ratio: contrast(value(fg), value(bg)), min }))
    .filter((f) => f.ratio < f.min);
}
/** Every pair of every theme: a colour is good for all of them, so changing theme can never fail. */
export const failures = (color: string, darkColor = "", scheme?: Scheme): Failure[] =>
  THEMES.flatMap((theme) =>
    (scheme ? [scheme] : SCHEMES).flatMap((s) => check(theme, s, derive(theme, s, color, darkColor))),
  );
/** The closest lightness of the same hue that passes everywhere; darker first when it is a draw. */
export function nearest(color: string, darkColor = "", which: Scheme = "light"): string {
  const from = oklch((which === "dark" ? darkColor : color).toLowerCase());
  const good = (hex: string) =>
    which === "dark" ? failures(color, hex, "dark").length === 0 : failures(hex, darkColor).length === 0;
  for (let k = 0; k <= 200; k++)
    for (const l of k === 0 ? [from.l] : [from.l - 0.005 * k, from.l + 0.005 * k]) {
      if (l < 0 || l > 1) continue;
      const hex = paint(l, from.c, from.x, from.y);
      if (good(hex)) return hex;
    }
  throw new Error("No colour passes");
}

// ---- stylesheet ----
/** Every CSS variable of one scheme. Which logo shows depends on the header's ground, not on the scheme. */
export function variables(tokens: Tokens): Record<string, string> {
  const dark = contrast(tokens["masthead-bg"] as string, "#ffffff") >= 4.5;
  return {
    ...Object.fromEntries(Object.entries(tokens).map(([k, v]) => [`--color-${k}`, v])),
    "--logo-on-light": dark ? "none" : "block",
    "--logo-on-dark": dark ? "block" : "none",
  };
}
const vars = (tokens: Tokens, pad: string) =>
  Object.entries(variables(tokens))
    .map(([k, v]) => `${pad}${k}: ${v};`)
    .join("\n");
/** `root` outranks the bundled default, so the order of the two stylesheets does not matter. */
export const stylesheet = (light: Tokens, dark: Tokens, root = "html:root") => `${root} {
  color-scheme: light;
${vars(light, "  ")}
}
${root}[data-theme="dark"] {
  color-scheme: dark;
${vars(dark, "  ")}
}
@media (prefers-color-scheme: dark) {
  ${root}:not([data-theme="light"]) {
    color-scheme: dark;
${vars(dark, "    ")}
  }
}
`;
