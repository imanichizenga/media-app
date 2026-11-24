"""Brand colour → every token of every theme. Port of support/packages/design-tokens/src/theme.ts, judged by the
shared vectors: the rules are support/packages/design-tokens/spec/derivation.md."""

import json
from collections.abc import Iterable
from dataclasses import dataclass
from functools import lru_cache
from math import floor, sqrt
from pathlib import Path
from typing import Any, Literal

Scheme = Literal["light", "dark"]
Tokens = dict[str, str]
SPEC: dict[str, Any] = json.loads(Path(__file__).with_name("themes.json").read_text(encoding="utf-8"))
THEMES: tuple[str, ...] = tuple(SPEC["themes"])
CHOICES = [(k, k) for k in THEMES]
SCHEMES: tuple[Scheme, ...] = ("light", "dark")
PAIRS: tuple[tuple[str, str, float], ...] = tuple((f, b, m) for f, b, m in SPEC["pairs"])


# ---- colour ----
@lru_cache(maxsize=4096)
def _channels(hex_: str) -> tuple[float, float, float]:
    r, g, b = (int(hex_[i : i + 2], 16) / 255 for i in (1, 3, 5))
    return _decode(r), _decode(g), _decode(b)


def _decode(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else float(((c + 0.055) / 1.055) ** 2.4)


def _encode(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else float(1.055 * c ** (1 / 2.4) - 0.055)


@lru_cache(maxsize=4096)
def _luminance(hex_: str) -> float:
    r, g, b = _channels(hex_)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    x, y = _luminance(a), _luminance(b)
    return (max(x, y) + 0.05) / (min(x, y) + 0.05)


@dataclass(frozen=True, slots=True)
class Oklch:
    """Lightness, chroma and the direction of the hue."""

    l: float  # noqa: E741
    c: float
    x: float
    y: float


def oklch(hex_: str) -> Oklch:
    r, g, b = _channels(hex_)
    p = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    q = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    light = 0.2104542553 * p + 0.793617785 * q - 0.0040720468 * s
    a = 1.9779984951 * p - 2.428592205 * q + 0.4505937099 * s
    b_ = 0.0259040371 * p + 0.7827717662 * q - 0.808675766 * s
    c = sqrt(a * a + b_ * b_)
    return Oklch(light, 0.0, 0.0, 0.0) if c < 0.0005 else Oklch(light, c, a / c, b_ / c)


def _linear(light: float, c: float, x: float, y: float) -> tuple[float, float, float]:
    a, b = c * x, c * y
    p = light + 0.3963377774 * a + 0.2158037573 * b
    q = light - 0.1055613458 * a - 0.0638541728 * b
    s = light - 0.0894841775 * a - 1.291485548 * b
    p3, q3, s3 = p * p * p, q * q * q, s * s * s
    return (
        4.0767416621 * p3 - 3.3077115913 * q3 + 0.2309699292 * s3,
        -1.2684380046 * p3 + 2.6097574011 * q3 - 0.3413193965 * s3,
        -0.0041960863 * p3 - 0.7034186147 * q3 + 1.707614701 * s3,
    )


def _inside(rgb: Iterable[float]) -> bool:
    return all(-0.0001 <= v <= 1.0001 for v in rgb)


def paint(light: float, c: float, x: float, y: float) -> str:
    """The nearest colour a screen can show: lightness and hue are kept, chroma gives way."""
    rgb = _linear(light, c, x, y)
    if not _inside(rgb):
        low, high = 0.0, c
        for _ in range(20):
            mid = (low + high) / 2
            if _inside(_linear(light, mid, x, y)):
                low = mid
            else:
                high = mid
        rgb = _linear(light, low, x, y)
    return "#" + "".join(f"{floor(_encode(min(1.0, max(0.0, v))) * 255 + 0.5):02x}" for v in rgb)


# ---- derivation ----
def derive(theme: str, scheme: Scheme, color: str, dark_color: str = "") -> Tokens:
    source = SPEC["themes"][theme][scheme]
    override = scheme == "dark" and dark_color != ""
    base = (dark_color if override else color).lower()
    o = oklch(base)
    out: Tokens = dict(source["neutral"])

    def value(name: str) -> str:
        return name if name.startswith("#") else out[name]

    def walk(start: float, step: float, c: float, grounds: list[str], minimum: float) -> str:
        i = 0
        while True:
            light = start + step * i
            hex_ = paint(light, c, o.x, o.y)
            if light >= 1 or all(contrast(hex_, g) >= minimum for g in grounds):
                return hex_
            i += 1

    for name, rule in source["brand"].items():
        if isinstance(rule, str):
            out[name] = value(rule[1:]) if rule.startswith("@") else rule
            continue
        op, *rest = rule
        if op == "exact":
            out[name] = base
        elif op == "fill":
            out[name] = walk(0.3, 0.0025, o.c * 0.92, [value(r) for r in rest], 3)
        elif op == "soften":
            out[name] = (
                base if override else walk(0.64, 0.005, min(o.c * 0.9, 0.17), [value(r) for r in rest], 4.5)
            )
        elif op == "strong":
            f = oklch(value(rest[0]))
            out[name] = paint(max(0.0, f.l - 0.055), f.c, f.x, f.y)
        elif op == "tint":
            out[name] = paint(rest[0], min(o.c, rest[1]), o.x, o.y)
        else:
            raise ValueError(f"Unknown rule {op}")
    return out


# ---- validation ----
@dataclass(frozen=True, slots=True)
class Failure:
    theme: str
    scheme: Scheme
    fg: str
    bg: str
    ratio: float
    min: float


def check(theme: str, scheme: Scheme, tokens: Tokens) -> list[Failure]:
    def value(name: str) -> str:
        return name if name.startswith("#") else tokens[name]

    found = (Failure(theme, scheme, f, b, contrast(value(f), value(b)), m) for f, b, m in PAIRS)
    return [f for f in found if f.ratio < f.min]


def failures(color: str, dark_color: str = "", scheme: Scheme | None = None) -> list[Failure]:
    """Every pair of every theme: a colour is good for all of them, so changing theme can never fail."""
    return [
        f
        for theme in THEMES
        for s in ((scheme,) if scheme else SCHEMES)
        for f in check(theme, s, derive(theme, s, color, dark_color))
    ]


def nearest(color: str, dark_color: str = "", which: Scheme = "light") -> str:
    """The closest lightness of the same hue that passes everywhere; darker first when it is a draw."""
    start = oklch((dark_color if which == "dark" else color).lower())

    def good(hex_: str) -> bool:
        return not (failures(color, hex_, "dark") if which == "dark" else failures(hex_, dark_color))

    for k in range(201):
        for light in (start.l,) if k == 0 else (start.l - 0.005 * k, start.l + 0.005 * k):
            if 0 <= light <= 1:
                hex_ = paint(light, start.c, start.x, start.y)
                if good(hex_):
                    return hex_
    raise ValueError("No colour passes")


# ---- stylesheet ----
def variables(tokens: Tokens) -> dict[str, str]:
    """Every CSS variable of one scheme. Which logo shows depends on the header, not on the scheme."""
    dark = contrast(tokens["masthead-bg"], "#ffffff") >= 4.5
    return {
        **{f"--color-{k}": v for k, v in tokens.items()},
        "--logo-on-light": "none" if dark else "block",
        "--logo-on-dark": "block" if dark else "none",
    }


def _vars(tokens: Tokens, pad: str) -> str:
    return "\n".join(f"{pad}{k}: {v};" for k, v in variables(tokens).items())


def stylesheet(light: Tokens, dark: Tokens, root: str = "html:root") -> str:
    """`root` outranks the bundled default, so the order of the two stylesheets does not matter."""
    return f"""{root} {{
  color-scheme: light;
{_vars(light, "  ")}
}}
{root}[data-theme="dark"] {{
  color-scheme: dark;
{_vars(dark, "  ")}
}}
@media (prefers-color-scheme: dark) {{
  {root}:not([data-theme="light"]) {{
    color-scheme: dark;
{_vars(dark, "    ")}
  }}
}}
"""
