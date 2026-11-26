from dataclasses import dataclass
from typing import Any
from uuid import UUID

from newsplatform.taxonomy.models import Category, Tag, Visibility


@dataclass(frozen=True, slots=True)
class Node:
    category: Category
    texts: dict[str, Any]  # locale → CategoryText

    def name(self, locale: str) -> str:
        text = self.texts.get(locale) or next(iter(self.texts.values()))
        return str(text.name)

    def short_name(self, locale: str) -> str:
        text = self.texts.get(locale) or next(iter(self.texts.values()))
        return str(text.short_name or text.name)

    def slug(self, locale: str) -> str:
        text = self.texts.get(locale) or next(iter(self.texts.values()))
        return str(text.slug)


def tree(*, public_only: bool = False) -> dict[UUID, Node]:
    """All categories in display order. A few hundred rows at most, always two queries."""
    rows = Category.objects.prefetch_related("texts").order_by("depth", "position", "id")
    if public_only:
        rows = rows.filter(visibility=Visibility.PUBLIC)
    nodes = {c.pk: Node(c, {t.locale: t for t in c.texts.all()}) for c in rows}
    if public_only:  # a hidden parent hides its branch
        nodes = {k: n for k, n in nodes.items() if all(a in nodes for a in n.category.ancestors)}
    return nodes


def scope_chain(category_id: str) -> set[str]:
    try:
        row = Category.objects.filter(pk=UUID(category_id)).values_list("ancestors", flat=True).first()
    except ValueError:
        return set()
    return set() if row is None else {category_id, *map(str, row)}


def policy_chain(category: Category) -> list[dict[str, Any]]:
    """Engagement overrides, root first."""
    rows = dict(Category.objects.filter(pk__in=category.ancestors).values_list("pk", "engagement"))
    return [*(rows.get(a, {}) for a in category.ancestors), category.engagement]


def find_tags(words: list[str]) -> dict[str, Tag]:
    """Word → tag, through slugs, names and synonyms, following merges."""
    found: dict[str, Tag] = {}
    for word in words:
        key = word.strip().lower()
        tag = (
            Tag.objects.filter(slug=key).first()
            or Tag.objects.filter(name_sw__iexact=key).first()
            or Tag.objects.filter(name_en__iexact=key).first()
            or Tag.objects.filter(synonyms__contains=[key]).first()
        )
        while tag and tag.merged_into:
            tag = tag.merged_into
        if tag:
            found[word] = tag
    return found
