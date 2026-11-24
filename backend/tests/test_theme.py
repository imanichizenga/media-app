"""The Python port of the theme derivation. The shared vectors are the referee for all three ports."""

import hashlib
import json
import random
from pathlib import Path

import pytest

from newsplatform.site_config.theme import derive as t

PACKAGE = Path(__file__).parents[2] / "support/packages/design-tokens"
VECTORS = json.loads((PACKAGE / "spec/vectors.json").read_text())


def test_themes_are_the_packages_own():
    assert (PACKAGE / "src/themes.json").read_text() == Path(t.__file__).with_name("themes.json").read_text()


def test_parity_with_the_other_ports():
    assert list(t.THEMES) == VECTORS["themes"]
    for case in VECTORS["cases"]:
        got = [
            "".join(v[1:] for v in t.derive(theme, scheme, case["color"], case["dark"]).values())
            for theme in t.THEMES
            for scheme in t.SCHEMES
        ]
        assert got == case["tokens"], case["color"]
        assert len(t.failures(case["color"], case["dark"])) == case["failures"]
        if "nearest" in case:
            assert t.nearest(case["color"]) == case["nearest"], case["color"]
        if "nearest_dark" in case:
            assert t.nearest("#b5121b", case["dark"], "dark") == case["nearest_dark"]
    assert list(t.derive("signature", "light", "#b5121b")) == VECTORS["order"]


def test_the_stylesheet_is_the_same_bytes():
    for theme, digest in VECTORS["css"].items():
        css = t.stylesheet(t.derive(theme, "light", "#b5121b"), t.derive(theme, "dark", "#b5121b"))
        assert hashlib.sha256(css.encode()).hexdigest() == digest


def test_paint_parity():
    for p in VECTORS["paints"]:
        assert t.paint(p["l"], *p["from"][1:]) == p["hex"]


@pytest.mark.parametrize("theme", t.THEMES)
@pytest.mark.parametrize("scheme", t.SCHEMES)
def test_default_colour_passes_everywhere(theme, scheme):
    assert t.check(theme, scheme, t.derive(theme, scheme, t.SPEC["color"])) == []


def test_any_colour_has_a_valid_neighbour_and_dark_never_fails_alone():
    rng = random.Random(7)
    for _ in range(40):
        color = f"#{rng.randrange(1 << 24):06x}"
        assert all(f.scheme == "light" for f in t.failures(color))
        assert t.failures(t.nearest(color)) == []


def test_dark_is_never_the_light_red():
    for theme in t.THEMES:
        light, dark = t.derive(theme, "light", "#b5121b"), t.derive(theme, "dark", "#b5121b")
        assert light["brand"] == "#b5121b"
        assert "#b5121b" not in dark.values()
        a, b = t.oklch(light["brand"]), t.oklch(dark["brand"])
        assert b.l > a.l
        assert b.c < a.c
