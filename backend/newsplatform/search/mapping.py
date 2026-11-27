"""The index of each language: its analysis and fields (ADR-0049). Changing this means a new index and
`search_reindex`."""

from __future__ import annotations

from typing import Any

from django.conf import settings

VERSION = (
    1  # raise with every change to SETTINGS or the fields; search_reindex builds `<alias>-v<VERSION>-<time>`
)
LOCALES = ("sw", "en")
MAX_RESULT_WINDOW = 1000  # 50 pages of 20 for readers; reconcile walks ids 1000 at a time

# Words that carry no meaning on their own in Swahili news text. Phrase matches still see them.
SWAHILI_STOP = [
    "na",
    "ya",
    "wa",
    "za",
    "la",
    "cha",
    "vya",
    "kwa",
    "katika",
    "ni",
    "si",
    "kuwa",
    "hii",
    "hiyo",
    "huo",
    "hilo",
    "hizo",
    "hayo",
    "huu",
    "yake",
    "wake",
    "zake",
    "lake",
    "chake",
    "vyake",
    "kama",
    "lakini",
    "au",
    "pia",
    "tu",
    "sana",
    "bado",
    "kwenye",
    "mwa",
    "kwamba",
    "ambao",
    "ambayo",
    "ambapo",
    "ambaye",
    "huku",
    "hata",
    "baada",
    "kabla",
    "hadi",
    "mpaka",
    "hapa",
    "pale",
    "kuna",
    "kila",
    "wao",
    "yeye",
    "sisi",
    "nyinyi",
    "mimi",
    "wewe",
    "hayo",
    "ili",
    "ndani",
    "nje",
    "juu",
    "chini",
    "zaidi",
]


def alias(locale: str) -> str:
    return f"{settings.OPENSEARCH_PREFIX}-{locale}"


def _text(analyzer: str) -> dict[str, Any]:
    return {"type": "text", "analyzer": analyzer}


def definition(locale: str) -> dict[str, Any]:
    words = "sw_text" if locale == "sw" else "en_text"
    prefix = {"type": "text", "analyzer": "prefix_index", "search_analyzer": "prefix_search"}
    return {
        "settings": {
            "number_of_shards": settings.OPENSEARCH_SHARDS,
            "number_of_replicas": settings.OPENSEARCH_REPLICAS,
            "refresh_interval": "5s",
            "max_result_window": MAX_RESULT_WINDOW,
            "analysis": {
                "filter": {
                    "sw_stop": {"type": "stop", "stopwords": SWAHILI_STOP},
                    "edge": {"type": "edge_ngram", "min_gram": 2, "max_gram": 15},
                    "english_possessive": {"type": "stemmer", "language": "possessive_english"},
                    "english_stop": {"type": "stop", "stopwords": "_english_"},
                    "english_stem": {
                        "type": "stemmer",
                        "language": "english",
                    },  # Porter, as the `english` analyzer
                },
                "analyzer": {
                    "sw_text": {"tokenizer": "standard", "filter": ["lowercase", "asciifolding", "sw_stop"]},
                    "en_text": {
                        "tokenizer": "standard",
                        "filter": [
                            "lowercase",
                            "asciifolding",
                            "english_possessive",
                            "english_stop",
                            "english_stem",
                        ],
                    },
                    "prefix_index": {
                        "tokenizer": "standard",
                        "filter": ["lowercase", "asciifolding", "edge"],
                    },
                    "prefix_search": {"tokenizer": "standard", "filter": ["lowercase", "asciifolding"]},
                    "exact": {"tokenizer": "standard", "filter": ["lowercase", "asciifolding"]},
                },
            },
        },
        "mappings": {
            "dynamic": "strict",
            "_source": {"excludes": ["body"]},
            "properties": {
                "post_id": {"type": "keyword"},
                "locale": {"type": "keyword"},
                "type": {"type": "keyword"},
                "path": {"type": "keyword", "index": False},
                "headline": {
                    **_text(words),
                    "fields": {"prefix": prefix, "exact": _text("exact")},
                },
                "standfirst": _text(words),
                # Stored apart from _source, so answers do not carry it but snippets can be cut from it.
                "body": {**_text(words), "store": True, "index_options": "offsets"},
                "tags": {**_text(words), "fields": {"prefix": prefix}},
                "tag_slugs": {"type": "keyword"},
                "authors": {**_text("exact"), "fields": {"prefix": prefix}},
                "author_slugs": {"type": "keyword"},
                "category": _text(words),
                "category_ids": {"type": "keyword"},
                "regions": {**_text("exact"), "fields": {"prefix": prefix}},
                "published_at": {"type": "date"},
                "modified_at": {"type": "date", "index": False},
                "etag": {"type": "keyword"},
                "card": {"type": "object", "enabled": False},
            },
        },
    }
