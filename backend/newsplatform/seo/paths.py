"""The only place that knows what public URLs look like (ADR-0024)."""

import re
import unicodedata

from newsplatform.common.locales import DEFAULT

# First segments the website uses itself, in either language.
RESERVED = frozenset(
    {
        "en",
        "sw",
        "api",
        "ws",
        "admin",
        "latest",
        "tag",
        "story",
        "author",
        "video",
        "shorts",
        "live",
        "search",
        "saved",
        "profile",
        "settings",
        "about",
        "contact",
        "privacy",
        "terms",
        "editorial-policy",
        "corrections",
        "rss",
        "feed",
        "sitemap",
        "sitemaps",
        "robots",
        "ads",
        "app-ads",
        "static",
        "_next",
        "monitoring",
        "healthz",
        "media",
        "images",
        "manifest",
        "offline",
        "missing",
        "skeletons",
        "document",
        "og",
        "js",
        "theme",
        "indexnow",
    }
)


def prefix(locale: str) -> str:
    return "" if locale == DEFAULT else f"/{locale}"


def category_path(locale: str, slug: str) -> str:
    return f"{prefix(locale)}/{slug}"


def post_path(locale: str, category_slug: str, slug: str) -> str:
    return f"{prefix(locale)}/{category_slug}/{slug}"


def tag_path(locale: str, slug: str) -> str:
    return f"{prefix(locale)}/tag/{slug}"


def story_path(locale: str, slug: str) -> str:
    return f"{prefix(locale)}/story/{slug}"


def author_path(locale: str, slug: str) -> str:
    return f"{prefix(locale)}/author/{slug}"


def page_path(locale: str, key: str) -> str:
    return f"{prefix(locale)}/{key}"


def slugify(text: str, limit: int = 80) -> str:
    """ASCII, whole words, never empty for text that has letters. Apostrophes join: ng'ombe → ngombe."""
    text = re.sub("['`\u2018\u2019]", "", text)
    plain = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()
    words = re.findall(r"[a-z0-9]+", plain)
    out = ""
    for word in words:
        joined = f"{out}-{word}" if out else word
        if len(joined) > limit:
            break
        out = joined
    return out or (words[0][:limit] if words else "")
