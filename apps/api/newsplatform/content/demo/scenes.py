"""Illustrations drawn by this code, so demo content needs nobody's photographs. The same seed, the same picture."""

import math
import random
from collections.abc import Callable

import pyvips

W, H = 1920, 1280
# sky top, sky low, sun, far, near, ground, accent
PALETTES = [
    ("#f6b26b", "#fde8c8", "#fff3d6", "#c97b4a", "#7a4a32", "#3d2a22", "#d9573f"),
    ("#8fc3e8", "#e4f2fb", "#ffffff", "#5f93b5", "#2f6b7d", "#1c4a52", "#f0b441"),
    ("#2a2f5b", "#c76b7e", "#ffd9a0", "#5b3f6b", "#34264d", "#1b1530", "#f5c15c"),
    ("#a8d5ba", "#f3f7e6", "#fffbe0", "#6ba583", "#3c7a57", "#23513a", "#e0703c"),
    ("#d9cfe8", "#f8f0f4", "#ffffff", "#9d88b8", "#655487", "#3b3157", "#e9a13b"),
    ("#f2c9a1", "#fbeee0", "#fff8ea", "#b98a63", "#6f5a49", "#403831", "#2f7f8c"),
]


def _ridge(rng: random.Random, base: float, height: float, color: str, w: int, h: int, step: int = 80) -> str:
    phase, points = rng.random() * 9, []
    for x in range(-step, w + step * 2, step):
        y = base - height * (0.55 + 0.35 * math.sin(x / 330 + phase) + 0.18 * math.sin(x / 120 + phase * 2))
        points.append(f"{x},{y:.0f}")
    return f'<polygon fill="{color}" points="-80,{h} {" ".join(points)} {w + 160},{h}"/>'


def _tree(x: float, y: float, s: float, color: str) -> str:
    crown = "".join(
        f'<ellipse cx="{x + dx * s:.0f}" cy="{y - dy * s:.0f}" rx="{rx * s:.0f}" ry="{ry * s:.0f}"/>'
        for dx, dy, rx, ry in ((0, 150, 120, 26), (-60, 132, 80, 22), (70, 138, 90, 22))
    )
    trunk = (
        f'<path d="M{x - 6 * s:.0f} {y:.0f} Q{x:.0f} {y - 70 * s:.0f} {x - 46 * s:.0f} {y - 130 * s:.0f} '
        f'M{x:.0f} {y:.0f} Q{x + 6 * s:.0f} {y - 80 * s:.0f} {x + 54 * s:.0f} {y - 132 * s:.0f}" '
        f'stroke="{color}" stroke-width="{11 * s:.0f}" fill="none"/>'
    )
    return f'<g fill="{color}">{crown}</g>{trunk}'


def _savanna(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = _ridge(rng, h * 0.66, 190, p[3], w, h) + _ridge(rng, h * 0.76, 120, p[4], w, h)
    out += f'<rect y="{h * 0.78:.0f}" width="{w}" height="{h}" fill="{p[5]}"/>'
    for _ in range(4):
        s = 0.8 + rng.random() * 1.7
        out += _tree(rng.random() * w, h * 0.79, s, p[5])
    return out


def _mountain(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    c, top, base = w * (0.4 + rng.random() * 0.25), h * 0.28, h * 0.94
    out = f'<polygon fill="{p[3]}" points="{c - w * 0.5:.0f},{base:.0f} {c - 130:.0f},{top:.0f} {c + 120:.0f},{top + 14:.0f} {c + w * 0.55:.0f},{base:.0f}"/>'
    out += f'<path fill="#ffffff" opacity=".88" d="M{c - 130:.0f} {top:.0f} L{c + 120:.0f} {top + 14:.0f} L{c + 190:.0f} {top + 96:.0f} L{c + 100:.0f} {top + 64:.0f} L{c + 30:.0f} {top + 118:.0f} L{c - 50:.0f} {top + 60:.0f} L{c - 130:.0f} {top + 122:.0f} L{c - 205:.0f} {top + 92:.0f}Z"/>'
    out += _ridge(rng, h * 0.8, 120, p[4], w, h) + _ridge(rng, h * 0.93, 110, p[5], w, h)
    return out


def _dhow(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    sea = h * 0.62
    out = f'<rect y="{sea:.0f}" width="{w}" height="{h}" fill="{p[4]}"/>'
    for i in range(26):
        y = sea + 14 + i * i * 0.9
        x, length = rng.random() * w, 60 + rng.random() * 260
        out += f'<rect x="{x:.0f}" y="{y:.0f}" width="{length:.0f}" height="{3 + i * 0.25:.0f}" rx="3" fill="{p[1]}" opacity=".22"/>'
    for _ in range(3):
        s, x = 0.6 + rng.random() * 1.2, w * (0.12 + rng.random() * 0.76)
        y = sea + 60 * s + rng.random() * 130
        out += (
            f'<path fill="{p[5]}" d="M{x - 130 * s:.0f} {y:.0f} q{130 * s:.0f} {70 * s:.0f} {270 * s:.0f} {-12 * s:.0f} l{-24 * s:.0f} {44 * s:.0f} q{-110 * s:.0f} {26 * s:.0f} {-220 * s:.0f} 0Z"/>'
            f'<path fill="{p[2]}" d="M{x - 20 * s:.0f} {y - 4 * s:.0f} L{x + 46 * s:.0f} {y - 300 * s:.0f} Q{x + 170 * s:.0f} {y - 120 * s:.0f} {x + 120 * s:.0f} {y - 14 * s:.0f}Z"/>'
            f'<rect x="{x - 24 * s:.0f}" y="{y - 260 * s:.0f}" width="{8 * s:.0f}" height="{270 * s:.0f}" fill="{p[5]}"/>'
        )
    return out


def _city(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = ""
    for layer, color in ((0, p[3]), (1, p[4]), (2, p[5])):
        x: float = -20
        while x < w:
            bw = 80 + rng.random() * 150
            bh = h * (0.5 - layer * 0.1) * (0.45 + rng.random() * 0.6)
            y = h - bh - (2 - layer) * 40
            out += f'<rect x="{x:.0f}" y="{y:.0f}" width="{bw:.0f}" height="{h}" rx="4" fill="{color}"/>'
            if layer:
                for wx in range(int(x) + 16, int(x + bw) - 20, 30):
                    for wy in range(int(y) + 22, h, 42):
                        if rng.random() < 0.42:
                            out += f'<rect x="{wx}" y="{wy}" width="13" height="19" rx="2" fill="{p[2]}" opacity=".7"/>'
            x += bw + rng.random() * 26
    return out


def _stadium(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = f'<ellipse cx="{w / 2:.0f}" cy="{h * 0.62:.0f}" rx="{w * 0.62:.0f}" ry="{h * 0.36:.0f}" fill="{p[5]}"/>'
    for i in range(620):
        a, r = rng.random() * math.pi * 2, 0.74 + rng.random() * 0.24
        x, y = w / 2 + math.cos(a) * w * 0.6 * r, h * 0.62 + math.sin(a) * h * 0.34 * r
        out += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="7" fill="{(p[6], p[1], p[2], p[3])[i % 4]}" opacity=".85"/>'
    out += f'<ellipse cx="{w / 2:.0f}" cy="{h * 0.66:.0f}" rx="{w * 0.42:.0f}" ry="{h * 0.22:.0f}" fill="#3f8f4f"/>'
    for i in range(6):
        out += f'<rect x="{w * 0.2 + i * w * 0.105:.0f}" y="{h * 0.46:.0f}" width="{w * 0.052:.0f}" height="{h * 0.4:.0f}" fill="#ffffff" opacity=".06"/>'
    out += f'<g fill="none" stroke="#fff" stroke-width="6" opacity=".8"><ellipse cx="{w / 2:.0f}" cy="{h * 0.66:.0f}" rx="130" ry="64"/><path d="M{w / 2:.0f} {h * 0.45:.0f}V{h * 0.87:.0f}"/></g>'
    out += f'<circle cx="{w * 0.58:.0f}" cy="{h * 0.72:.0f}" r="17" fill="#fff"/>'
    return out


def _market(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = f'<rect y="{h * 0.6:.0f}" width="{w}" height="{h}" fill="{p[4]}"/>'
    for row in range(2):
        y = h * (0.46 + row * 0.2)
        for i in range(5):
            x, sw = i * w / 4.6 - 80 + row * 90, w / 5.2
            cloth = (p[6], p[2], p[3], "#3f8f6f")[(i + row) % 4]
            out += f'<rect x="{x:.0f}" y="{y:.0f}" width="{sw:.0f}" height="{h * 0.34:.0f}" fill="{p[5]}"/>'
            for k in range(6):
                fill = cloth if k % 2 else "#fffaf0"
                out += f'<path fill="{fill}" d="M{x - 24 + k * (sw + 48) / 6:.0f} {y - 80:.0f} h{(sw + 48) / 6:.0f} v118 a{(sw + 48) / 12:.0f} 34 0 0 1 {-(sw + 48) / 6:.0f} 0Z"/>'
            for k in range(26):
                fx, fy = x + 16 + (k % 13) * (sw - 32) / 12, y + h * 0.2 - (k // 13) * 24
                out += f'<circle cx="{fx:.0f}" cy="{fy:.0f}" r="17" fill="{("#e0562f", "#f0b441", "#5a9a3c", "#b8336a")[(k + i) % 4]}"/>'
            out += f'<rect x="{x - 8:.0f}" y="{y + h * 0.21:.0f}" width="{sw + 16:.0f}" height="{h * 0.16:.0f}" fill="{p[3]}"/>'
    return out


def _farm(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = _ridge(rng, h * 0.56, 120, p[3], w, h)
    out += f'<rect y="{h * 0.55:.0f}" width="{w}" height="{h}" fill="#5f8f45"/>'
    vx = w * (0.35 + rng.random() * 0.3)
    for i in range(-16, 17):
        x = vx + i * 190
        out += f'<path d="M{vx + i * 9:.0f} {h * 0.55:.0f} L{x:.0f} {h} l70 0 L{vx + i * 9 + 5:.0f} {h * 0.55:.0f}Z" fill="{"#3f6d2f" if i % 2 else "#86ad56"}"/>'
    return out + _tree(w * 0.14, h * 0.6, 1.3, p[5]) + _tree(w * 0.88, h * 0.58, 1.0, p[5])


def _parliament(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    c, base = w / 2, h * 0.8
    out = _ridge(rng, h * 0.66, 90, p[3], w, h)
    out += f'<rect y="{base:.0f}" width="{w}" height="{h}" fill="{p[5]}"/>'
    out += f'<g fill="{p[2]}"><rect x="{c - 520:.0f}" y="{base - 280:.0f}" width="1040" height="280"/><polygon points="{c - 280:.0f},{base - 280:.0f} {c:.0f},{base - 400:.0f} {c + 280:.0f},{base - 280:.0f}"/><path d="M{c - 150:.0f} {base - 390:.0f} a150 150 0 0 1 300 0Z"/></g>'
    for i in range(13):
        out += f'<rect x="{c - 490 + i * 78:.0f}" y="{base - 250:.0f}" width="34" height="250" fill="{p[4]}" opacity=".8"/>'
    out += f'<rect x="{c - 4:.0f}" y="{base - 690:.0f}" width="8" height="160" fill="{p[5]}"/><path d="M{c + 4:.0f} {base - 686:.0f} q60 -22 120 0 t90 0 v70 q-60 22 -110 0 t-100 0Z" fill="{p[6]}"/>'
    for i in range(5):
        out += f'<rect x="{c - 580 - i * 24:.0f}" y="{base + i * 20:.0f}" width="{1160 + i * 48}" height="18" fill="{p[1]}" opacity=".7"/>'
    return out


def _signal(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = _ridge(rng, h * 0.92, 160, p[5], w, h)
    nodes = [(rng.random() * w, h * (0.12 + rng.random() * 0.6)) for _ in range(34)]
    for i, (x, y) in enumerate(nodes):
        near = sorted(nodes, key=lambda n: (n[0] - x) ** 2 + (n[1] - y) ** 2)[1:4]
        for nx, ny in near:
            out += f'<path d="M{x:.0f} {y:.0f}L{nx:.0f} {ny:.0f}" stroke="{p[4]}" stroke-width="3" opacity=".45"/>'
        out += (
            f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{9 + (i % 4) * 6}" fill="{p[6] if i % 5 == 0 else p[4]}"/>'
        )
    return out


def _clinic(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = _ridge(rng, h * 0.7, 130, p[3], w, h)
    out += f'<rect y="{h * 0.74:.0f}" width="{w}" height="{h}" fill="{p[4]}"/>'
    out += f'<rect x="{w * 0.2:.0f}" y="{h * 0.4:.0f}" width="{w * 0.6:.0f}" height="{h * 0.38:.0f}" fill="#fffdf8"/><rect x="{w * 0.17:.0f}" y="{h * 0.36:.0f}" width="{w * 0.66:.0f}" height="60" fill="{p[6]}"/>'
    for i in range(6):
        out += f'<rect x="{w * 0.235 + i * w * 0.095:.0f}" y="{h * 0.5:.0f}" width="{w * 0.06:.0f}" height="{h * 0.1:.0f}" rx="6" fill="{p[3]}"/>'
    out += f'<g fill="{p[6]}"><rect x="{w / 2 - 22:.0f}" y="{h * 0.63:.0f}" width="44" height="130" rx="6"/><rect x="{w / 2 - 65:.0f}" y="{h * 0.63 + 43:.0f}" width="130" height="44" rx="6"/></g>'
    return out + _tree(w * 0.09, h * 0.82, 1.5, p[5]) + _tree(w * 0.93, h * 0.8, 1.2, p[5])


def _stage(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = f'<rect width="{w}" height="{h}" fill="{p[5]}"/>'
    for i in range(6):
        x = w * (0.08 + i * 0.168)
        out += f'<polygon points="{x:.0f},0 {x - 190 + rng.random() * 120:.0f},{h} {x + 190 + rng.random() * 120:.0f},{h}" fill="{(p[6], p[3], p[0])[i % 3]}" opacity=".32"/>'
    out += f'<rect y="{h * 0.72:.0f}" width="{w}" height="60" fill="{p[4]}"/>'
    for i in range(48):
        x, y = i * w / 46 - 20, h * 0.86 + rng.random() * 60
        out += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="42" fill="#0d0a16"/><rect x="{x - 44:.0f}" y="{y + 26:.0f}" width="88" height="{h}" rx="40" fill="#0d0a16"/>'
        if i % 5 == 1:
            out += f'<path d="M{x - 20:.0f} {y + 30:.0f} L{x - 44:.0f} {y - 110:.0f}" stroke="#0d0a16" stroke-width="22" stroke-linecap="round"/>'
    return out


def _chart(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out, y, line = "", h * 0.66, []
    for i in range(14):
        bh = h * (0.14 + 0.03 * i + rng.random() * 0.12)
        x = w * 0.08 + i * w * 0.062
        out += f'<rect x="{x:.0f}" y="{h * 0.88 - bh:.0f}" width="{w * 0.04:.0f}" height="{bh:.0f}" rx="8" fill="{p[4] if i % 3 else p[3]}"/>'
        y = h * 0.8 - bh * 0.95 - 40
        line.append(f"{x + w * 0.02:.0f},{y:.0f}")
    out += f'<polyline points="{" ".join(line)}" fill="none" stroke="{p[6]}" stroke-width="14" stroke-linejoin="round" stroke-linecap="round"/>'
    return (
        out
        + f'<rect x="{w * 0.06:.0f}" y="{h * 0.88:.0f}" width="{w * 0.88:.0f}" height="8" rx="4" fill="{p[5]}"/>'
    )


def _school(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = f'<rect width="{w}" height="{h}" fill="{p[1]}"/><rect y="{h * 0.8:.0f}" width="{w}" height="{h}" fill="{p[3]}"/>'
    out += f'<rect x="{w * 0.16:.0f}" y="{h * 0.14:.0f}" width="{w * 0.68:.0f}" height="{h * 0.48:.0f}" rx="12" fill="#23473b" stroke="{p[4]}" stroke-width="22"/>'
    for i in range(5):
        out += f'<rect x="{w * 0.21:.0f}" y="{h * (0.21 + i * 0.075):.0f}" width="{w * (0.2 + rng.random() * 0.36):.0f}" height="12" rx="6" fill="#f4f7ef" opacity=".75"/>'
    for i in range(7):
        x = w * (0.05 + i * 0.145)
        out += f'<circle cx="{x:.0f}" cy="{h * 0.78:.0f}" r="64" fill="{("#3a2419", "#4a2f20", "#2c1b12")[i % 3]}"/><rect x="{x - 88:.0f}" y="{h * 0.83:.0f}" width="176" height="{h}" rx="60" fill="{(p[6], "#fffaf0", p[4])[i % 3]}"/>'
    return out


def _road(rng: random.Random, p: tuple[str, ...], w: int, h: int) -> str:
    out = _ridge(rng, h * 0.6, 200, p[3], w, h) + _ridge(rng, h * 0.7, 120, p[4], w, h)
    out += f'<rect y="{h * 0.68:.0f}" width="{w}" height="{h}" fill="{p[4]}"/>'
    out += f'<polygon points="{w * 0.48:.0f},{h * 0.62:.0f} {w * 0.52:.0f},{h * 0.62:.0f} {w * 0.86:.0f},{h} {w * 0.14:.0f},{h}" fill="#3c3b40"/>'
    for i in range(7):
        t = i / 7
        y, s = h * (0.63 + 0.37 * t * t), 4 + 36 * t
        out += f'<rect x="{w / 2 - s / 3:.0f}" y="{y:.0f}" width="{s / 1.5:.0f}" height="{s * 1.7:.0f}" fill="#f5e6b8"/>'
    bx, by = w * 0.57, h * 0.72
    out += f'<rect x="{bx:.0f}" y="{by - 170:.0f}" width="210" height="190" rx="24" fill="{p[6]}"/><rect x="{bx + 20:.0f}" y="{by - 146:.0f}" width="170" height="74" rx="10" fill="{p[1]}"/><g fill="#211f24"><circle cx="{bx + 48:.0f}" cy="{by + 20:.0f}" r="28"/><circle cx="{bx + 162:.0f}" cy="{by + 20:.0f}" r="28"/></g>'
    return out + _tree(w * 0.1, h * 0.86, 1.6, p[5])


SCENES: dict[str, Callable[[random.Random, tuple[str, ...], int, int], str]] = {
    "savanna": _savanna,
    "mountain": _mountain,
    "dhow": _dhow,
    "city": _city,
    "stadium": _stadium,
    "market": _market,
    "farm": _farm,
    "parliament": _parliament,
    "signal": _signal,
    "clinic": _clinic,
    "stage": _stage,
    "chart": _chart,
    "school": _school,
    "road": _road,
}
_FLAT = {"stage", "school"}


def _svg(inner: str, p: tuple[str, ...], sun: str, w: int, h: int) -> bytes:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"><defs>'
        f'<linearGradient id="s" x2="0" y2="1"><stop stop-color="{p[0]}"/><stop offset="1" stop-color="{p[1]}"/>'
        f'</linearGradient></defs><rect width="{w}" height="{h}" fill="url(#s)"/>{sun}{inner}</svg>'
    ).encode()


def draw(name: str, seed: int, *, vertical: bool = False) -> bytes:
    """A JPEG with light film grain, so variants compress like photographs rather than like icons."""
    w, h = (1080, 1920) if vertical else (W, H)
    rng = random.Random(f"{name}-{seed}-{vertical}")  # noqa: S311 (pictures, not secrets)
    p = PALETTES[seed % len(PALETTES)]
    sx, sy, r = w * (0.15 + rng.random() * 0.7), h * (0.16 + rng.random() * 0.16), 70 + rng.random() * 70
    glow = "".join(
        f'<circle cx="{sx:.0f}" cy="{sy:.0f}" r="{r * k:.0f}" fill="{p[2]}" opacity="{o}"/>'
        for k, o in ((2.6, 0.12), (1.7, 0.2), (1, 0.95))
    )
    svg = _svg(SCENES[name](rng, p, w, h), p, "" if name in _FLAT else glow, w, h)
    return _finish(pyvips.Image.svgload_buffer(svg), seed)


def portrait(seed: int) -> bytes:
    rng = random.Random(f"portrait-{seed}")  # noqa: S311
    p = PALETTES[seed % len(PALETTES)]
    skin = ("#5b3a29", "#6f4832", "#4a2d20", "#7c5238")[seed % 4]
    hair = ("#17110d", "#241812", "#0f0b09")[seed % 3]
    wrap = (
        f'<path d="M350 430 a250 250 0 0 1 500 0 l10 70 q-260 -150 -520 0Z" fill="{p[6]}"/>'
        if seed % 3 == 0
        else f'<path d="M370 470 a{230 + rng.random() * 40:.0f} 240 0 0 1 460 0 q-230 -170 -460 0Z" fill="{hair}"/>'
    )
    inner = (
        f'<circle cx="600" cy="620" r="560" fill="{p[3]}" opacity=".35"/>'
        f'<path d="M200 1200 q40 -330 400 -330 t400 330Z" fill="{p[4]}"/><path d="M500 800 h200 v120 q-100 90 -200 0Z" fill="{skin}"/>'
        f'<ellipse cx="600" cy="590" rx="205" ry="255" fill="{skin}"/>{wrap}'
        f'<g fill="#1a1210"><circle cx="522" cy="590" r="17"/><circle cx="678" cy="590" r="17"/></g>'
        f'<path d="M540 715 q60 46 120 0" stroke="#fff" stroke-width="15" fill="none" stroke-linecap="round" opacity=".85"/>'
    )
    return _finish(pyvips.Image.svgload_buffer(_svg(inner, p, "", 1200, 1200)), seed)


def logo(dark: bool) -> bytes:
    ink = "#f2f2f2" if dark else "#16181c"
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="960" height="240"><rect x="20" y="40" width="160" height="160" rx="36" '
        f'fill="{"#7db8f5" if dark else "#0b5cad"}"/><path d="M62 152 V88 l76 64 V88" stroke="{"#101114" if dark else "#fff"}" '
        f'stroke-width="22" fill="none" stroke-linejoin="round" stroke-linecap="round"/>'
        f'<g fill="{ink}"><rect x="226" y="76" width="420" height="34" rx="10"/><rect x="226" y="134" width="290" height="34" rx="10"/></g></svg>'
    ).encode()
    data: bytes = pyvips.Image.svgload_buffer(svg).pngsave_buffer()
    return data


def _finish(image: pyvips.Image, seed: int) -> bytes:
    image = image.flatten().colourspace("srgb")
    grain = pyvips.Image.gaussnoise(image.width, image.height, sigma=5, mean=0, seed=seed)
    data: bytes = (image + grain).cast("uchar").jpegsave_buffer(Q=90, keep="none")
    return data
