# The web's subsetted fonts, as the TTF files Flutter reads. Needs: pip install fonttools brotli
# Run after `pnpm install`, when a font package changes.
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).parents[2]
for name, out in (("inter", "Inter"), ("newsreader", "Newsreader")):
    package = ROOT / "admin/node_modules/@fontsource-variable" / name
    font = TTFont(package / f"files/{name}-latin-wght-normal.woff2")
    font.flavor = None
    font.save(ROOT / f"mobile/assets/fonts/{out}.ttf")
