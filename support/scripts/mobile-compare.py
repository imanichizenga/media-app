# Before and after, side by side. After drawing them (mobile/test/screens/native_gallery_test.dart):
#   backend/.venv/bin/python support/scripts/mobile-compare.py <before: a gallery's s/> mobile/build/gallery-native <out>
import html
import sys
from pathlib import Path

import pyvips

before, after, out = (Path(x) for x in sys.argv[1:4])
(out / "s").mkdir(parents=True, exist_ok=True)
for old in (out / "s").glob("*.jpg"):
    old.unlink()

# name, title, what changed, the screen before (theme, number and name)
SCREENS = [
    ("home", "Home", "S1, S2, N2, N3. No date; one row of tabs; one-line breaking; a low rail; the next story has begun.", ("signature", "01-home")),
    ("home-small", "Home at 360×640", "S1. The whole headline and its meta line stand above the bar.", None),
    ("home-scrolled", "Home, scrolled", "N4. The name gives way, the tabs stay.", ("signature", "02-home-stories")),
    ("home-feed", "Home, further down", "V1. The length of a video, no play mark.", ("signature", "04-home-video")),
    ("home-latest", "Home, Latest", "N3. A page one swipes to; it keeps its place.", None),
    ("home-english", "Home in English", "S1 in both languages.", None),
    ("home-bold", "Home, Bold Ink", "The same space in every theme.", ("bold", "01-home")),
    ("home-quiet", "Home, Quiet Paper", "The same space in every theme.", ("quiet", "01-home")),
    ("article", "Article", "S3, V3. A lower picture; headline, standfirst and byline in the first screen; neutral actions that cover nothing.", ("signature", "05-article")),
    ("article-reading", "Article, reading down", "S3. The actions step aside.", ("signature", "06-article-body")),
    ("article-bold", "Article, Bold Ink", "", ("bold", "05-article")),
    ("shorts", "Shorts", "N7. Two words on a soft scrim.", ("signature", "10-shorts")),
    ("videos", "Videos", "S2, V1. The platform's title bar; a play mark on the lead only.", ("signature", "11-videos")),
    ("explore", "Explore", "S2, N4.", ("signature", "12-explore")),
    ("category", "Category", "S1, S2. The lead comes sooner.", ("signature", "13-category")),
    ("author", "Journalist", "S2, S4. Meta on one line.", ("signature", "14-author")),
    ("saved", "Saved", "S2.", ("signature", "18-saved-empty")),
    ("you", "You", "V4. Grouped rows.", ("signature", "15-you")),
    ("choice", "A choice", "V4. The platform's own sheet.", None),
    ("menu", "A held card", "N5. Save, share, copy the link.", None),
    ("tablet-home", "Tablet, 1024", "S5. The latest beside the lead; three columns.", ("signature", "30-tablet-home")),
    ("tablet-article", "Tablet, article", "", ("signature", "31-tablet-article")),
    ("medium-home", "Small tablet, 768", "S5. Two columns.", ("signature", "32-medium-home")),
]  # fmt: skip


def put(path: Path, name: str, alt: str, label: str) -> str:
    image = pyvips.Image.new_from_file(str(path)).flatten()
    image = image.resize(min(1, (1000 if image.width > 1000 else 560) / image.width))
    image.jpegsave(str(out / "s" / f"{name}.jpg"), Q=80, keep="none")
    return (
        f'<figure><img loading="lazy" src="s/{name}.jpg" width="{image.width}" height="{image.height}" '
        f'alt="{html.escape(alt)}"><figcaption>{label}</figcaption></figure>'
    )


rows = []
count = 0
for name, title, note, was in SCREENS:
    for scheme in ("light", "dark"):
        cells = []
        if was:
            path = before / f"{was[0]}--{scheme}--sw--{was[1]}.jpg"
            if path.exists():
                cells.append(put(path, f"before--{scheme}--{name}", f"{title}, before, {scheme}", "Before"))
        for platform, label in (("android", "Android"), ("ios", "iPhone")):
            path = after / f"{platform}--{scheme}--{name}.png"
            if path.exists():
                cells.append(put(path, f"{platform}--{scheme}--{name}", f"{title}, {label}, {scheme}", label))
        count += len(cells)
        wide = " wide" if name.startswith(("tablet", "medium")) else ""
        rows.append(
            f'<section class="row{wide}" data-scheme="{scheme}"><header><h2>{html.escape(title)}</h2>'
            f"<p>{html.escape(note)}</p></header><div class=\"shots\">{''.join(cells)}</div></section>"
        )
page = Path(__file__).with_name("mobile-compare.html").read_text(encoding="utf-8")
(out / "index.html").write_text(page.replace("<!-- rows -->", "\n".join(rows)), encoding="utf-8")
print(f"{count} pictures")
