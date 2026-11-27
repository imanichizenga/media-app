"""A publication as the search engine holds it (ADR-0049)."""

from __future__ import annotations

from typing import Any

from newsplatform.content import selectors
from newsplatform.content.models import Publication

# Characters: longer stories are rare, and their first 30 000 hold the words people search for.
BODY_LIMIT = 30_000
_SKIP = {"id", "asset", "marks", "attrs", "src", "url", "href", "type", "level", "embed"}


def text_of(node: Any) -> list[str]:
    """Every piece of reader-visible text in the body's blocks, in order (paragraphs, headings, quotes,
    captions)."""
    out: list[str] = []

    def walk(value: Any) -> None:
        if isinstance(value, dict):
            for key, item in value.items():
                if key in _SKIP:
                    continue
                if key == "text" and isinstance(item, str):
                    out.append(item)
                else:
                    walk(item)
        elif isinstance(value, list):
            for item in value:
                walk(item)

    walk(node)
    return out


def body_text(article: dict[str, Any]) -> str:
    return " ".join(" ".join(text_of(article.get("body", {}))).split())[:BODY_LIMIT]


def _values(items: Any, key: str) -> list[str]:
    return [str(i[key]) for i in items or [] if isinstance(i, dict) and i.get(key)]


def document(row: Publication) -> dict[str, Any]:
    """With the category's parents, so a search in a section finds its subsections' stories too."""
    art, card = row.article, row.card
    return {
        "post_id": str(row.post_id),
        "locale": row.locale,
        "type": row.type,
        "path": row.path,
        "headline": card.get("headline", ""),
        "standfirst": card.get("standfirst", ""),
        "body": body_text(art),
        "tags": _values(art.get("tags"), "name"),
        "tag_slugs": _values(art.get("tags"), "slug"),
        "authors": _values(card.get("authors"), "name"),
        "author_slugs": _values(card.get("authors"), "slug"),
        "category": (card.get("category") or {}).get("name", ""),
        "category_ids": sorted({str(row.category_id), *(str(a) for a in row.category.ancestors)}),
        "regions": _values(art.get("regions"), "name"),
        "published_at": row.published_at.isoformat(),
        "modified_at": row.modified_at.isoformat(),
        "etag": row.etag,
        "card": selectors.card(row),  # exactly what the feeds give readers
    }
