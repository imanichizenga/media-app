"""The website's two fonts, made smaller: the weights the site uses (400 to 700), the characters Swahili and English need
(Latin), no hinting. They compete with the lead picture on a slow line: unsubsetted they cost about 450 ms of LCP
(measured with Lighthouse, M2). Writes web/fonts/{inter,newsreader}-latin.woff2; run again when a source changes.

    pip install --target /tmp/ft fonttools brotli
    PYTHONPATH=/tmp/ft python3 support/scripts/web-fonts.py
"""

from io import BytesIO
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parents[2]
SOURCES = {
    "inter": ROOT / "web/node_modules/@fontsource-variable/inter/files/inter-latin-wght-normal.woff2",
    "newsreader": ROOT / "web/node_modules/@fontsource-variable/newsreader/files/newsreader-latin-wght-normal.woff2",
}
WEIGHTS = (400, 700)
# Fontsource's "latin" range: Basic Latin, Latin-1, the punctuation and signs a newsroom types.
UNICODES = (
    "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,"
    "U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"
)
FEATURES = ["kern", "liga", "calt", "ccmp", "locl", "mark", "mkmk", "tnum", "case"]


def make(name: str, source: Path) -> Path:
    font = instancer.instantiateVariableFont(TTFont(source, lazy=False), {"wght": WEIGHTS})
    # Read again from bytes: the instancer leaves tables half-loaded, which the subsetter cannot walk.
    buffer = BytesIO()
    font.flavor = None
    font.save(buffer)
    buffer.seek(0)
    font = TTFont(buffer, lazy=False)
    options = subset.Options()
    options.flavor = "woff2"
    options.layout_features = FEATURES
    options.hinting = False
    options.desubroutinize = True
    options.name_IDs = ["*"]
    options.notdef_outline = True
    sub = subset.Subsetter(options)
    sub.populate(unicodes=subset.parse_unicodes(UNICODES))
    sub.subset(font)
    out = ROOT / f"web/fonts/{name}-latin.woff2"
    subset.save_font(font, str(out), options)
    return out


if __name__ == "__main__":
    for name, source in SOURCES.items():
        out = make(name, source)
        print(f"{out.relative_to(ROOT)}: {source.stat().st_size} → {out.stat().st_size} bytes")
