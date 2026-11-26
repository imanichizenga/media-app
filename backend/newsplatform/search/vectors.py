"""The Postgres search vector of each publication: headline A, standfirst, tags and writers B, body C
(ADR-0049)."""

from __future__ import annotations

from collections.abc import Iterable

from django.contrib.postgres.search import SearchVector
from django.db.models import Value

from newsplatform.content.models import Publication
from newsplatform.search.documents import document


def write(rows: Iterable[Publication]) -> None:
    for row in rows:
        doc = document(row)
        config = "english" if row.locale == "en" else "simple"
        middle = " ".join(
            [doc["standfirst"], *doc["tags"], *doc["authors"], *doc["regions"], doc["category"]]
        )
        Publication.objects.filter(pk=row.pk).update(
            search_vector=SearchVector(Value(doc["headline"]), weight="A", config=config)
            + SearchVector(Value(middle), weight="B", config=config)
            + SearchVector(Value(doc["body"]), weight="C", config=config)
        )
