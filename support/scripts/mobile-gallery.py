# The app's screenshots → one page to look at. After drawing them (mobile/test/screens/gallery_test.dart):
#   backend/.venv/bin/python support/scripts/mobile-gallery.py mobile/build/gallery <output folder>
import html
import sys
from pathlib import Path

import pyvips

source, out = Path(sys.argv[1]), Path(sys.argv[2])
(out / "s").mkdir(parents=True, exist_ok=True)
for old in (out / "s").glob("*.jpg"):
    old.unlink()
NAMES = {
    "home": "Home", "home-stories": "Home, top stories", "home-feed": "Home, feed", "home-video": "Home, video",
    "article": "Article", "article-body": "Article, reading", "article-quote": "Article, quote",
    "article-next": "Article, what comes next", "live-blog": "Live updates", "shorts": "Shorts", "videos": "Videos",
    "explore": "Explore", "category": "Category", "author": "Journalist", "you": "You", "photo": "Photo",
    "saved": "Saved", "saved-empty": "Saved, empty", "welcome": "Welcome", "language": "Language",
    "topics": "Topics", "offline": "Offline", "error": "Error", "update": "Update needed",
    "home-skeleton": "Home, loading", "article-skeleton": "Article, loading", "tablet-home": "Tablet, home",
    "tablet-article": "Tablet, article", "medium-home": "Small tablet, home",
}  # fmt: skip
figures = []
for path in sorted(source.glob("*.png"), key=lambda p: p.stem.split("--")[3]):
    theme, scheme, locale, screen = path.stem.split("--")
    image = pyvips.Image.new_from_file(str(path)).flatten()
    image = image.resize(min(1, (1000 if image.width > 1000 else 620) / image.width))
    image.jpegsave(str(out / "s" / f"{path.stem}.jpg"), Q=80, keep="none")
    name = NAMES[screen.split("-", 1)[1]]
    wide = " wide" if "tablet" in screen or "medium" in screen else ""
    figures.append(
        f'<figure class="shot{wide}" data-theme-key="{theme}" data-scheme="{scheme}" data-locale="{locale}">'
        f'<img loading="lazy" src="s/{path.stem}.jpg" width="{image.width}" height="{image.height}" '
        f'alt="{html.escape(name)}, {theme}, {scheme}, {locale}"><figcaption>{html.escape(name)}</figcaption></figure>'
    )
page = Path(__file__).with_name("mobile-gallery.html").read_text(encoding="utf-8")
(out / "index.html").write_text(page.replace("<!-- figures -->", "\n".join(figures)), encoding="utf-8")
print(f"{len(figures)} screens")
