"""Searching: OpenSearch when it answers, Postgres when it does not (ADR-0049). One shape for both."""

from __future__ import annotations

import base64
import json
import logging
import re
import unicodedata
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Literal

from django.contrib.postgres.search import SearchQuery, SearchRank, TrigramWordSimilarity
from django.db import connections, transaction
from django.db.models import Case, F, Q, Value, When
from django.db.models.fields.json import KeyTextTransform
from django.db.models.functions import Coalesce
from django.utils import timezone

from newsplatform.content import selectors
from newsplatform.content.models import Publication
from newsplatform.search import client, mapping

log = logging.getLogger(__name__)

PAGE = 20
MAX_PAGES = 50
SUGGESTIONS = 6
MAX_QUERY = 100
HIT, END = "\u0001", "\u0002"  # highlight marks: control characters never found in a story's text

Sort = Literal["relevance", "newest"]


def normalise(q: str) -> str:
    """Lower-case-insensitive later; here: no control characters, single spaces, at most 100 characters."""
    q = re.sub(r"[\x00-\x1f\x7f]", " ", q or "")
    return " ".join(q.split())[:MAX_QUERY]


@dataclass(frozen=True)
class Params:
    q: str
    locale: str
    types: tuple[str, ...] = ()
    categories: tuple[str, ...] = ()  # category ids; a section includes its subsections
    since: datetime | None = None
    sort: Sort = "relevance"
    cursor: str | None = None


@dataclass
class Hit:
    card: dict[str, Any]
    snippet: list[dict[str, Any]] = field(default_factory=list)  # [{"text": …, "hit": bool}]


@dataclass
class Page:
    results: list[Hit]
    next_cursor: str | None
    total: int
    total_is_exact: bool
    engine: Literal["opensearch", "fallback"]


def segments(marked: str) -> list[dict[str, Any]]:
    """`a \x01b\x02 c` → [{a, False}, {b, True}, {c, False}]; never markup."""
    out: list[dict[str, Any]] = []
    for part in re.split(f"({HIT}[^{END}]*{END})", marked):
        if not part:
            continue
        hit = part.startswith(HIT)
        text = part.strip(HIT + END) if hit else part
        if out and out[-1]["hit"] == hit:
            out[-1]["text"] += text
        else:
            out.append({"text": text, "hit": hit})
    return out


def _fold(text: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFKD", text.lower()) if not unicodedata.combining(c))


def plain_marks(parts: list[dict[str, Any]], q: str) -> list[dict[str, Any]]:
    """Typing mistakes find stories, but a word the reader spelled right is the only one marked:
    "wakazi" does not mark "wakati". Look-alikes stay marked only when nothing matches as typed,
    which is the reader's own mistake."""
    words = [w for w in re.findall(r"\w+", _fold(q)) if w]

    def plain(text: str) -> bool:
        folded = _fold(text)
        return any(folded.startswith(w) or (len(folded) >= 2 and w.startswith(folded)) for w in words)

    if not any(part["hit"] and plain(part["text"]) for part in parts):
        return parts
    out: list[dict[str, Any]] = []
    for part in parts:
        hit = part["hit"] and plain(part["text"])
        if out and out[-1]["hit"] == hit:
            out[-1]["text"] += part["text"]
        else:
            out.append({"text": part["text"], "hit": hit})
    return out


def _encode(values: list[Any], page: int) -> str:
    return (
        base64.urlsafe_b64encode(json.dumps([values, page], separators=(",", ":")).encode())
        .decode()
        .rstrip("=")
    )


def _decode(cursor: str | None) -> tuple[list[Any] | None, int]:
    if not cursor:
        return None, 1
    try:
        values, page = json.loads(base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)))
        if not isinstance(values, list) or not isinstance(page, int) or page < 1:
            raise ValueError
        return values, page
    except ValueError, TypeError, json.JSONDecodeError:
        return None, 1


# ----------------------------------------------------------------------------------------------------
# OpenSearch


def _filters(p: Params) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = [{"range": {"published_at": {"lte": "now"}}}]
    if p.types:
        out.append({"terms": {"type": list(p.types)}})
    if p.categories:
        out.append({"terms": {"category_ids": list(p.categories)}})
    if p.since:
        out[0]["range"]["published_at"]["gte"] = p.since.isoformat()
    return out


def _match(q: str) -> dict[str, Any]:
    return {
        "bool": {
            "should": [
                {
                    "multi_match": {
                        "query": q,
                        "type": "best_fields",
                        "fields": [
                            "headline^4",
                            "standfirst^2",
                            "tags^2",
                            "authors^2",
                            "category^1.5",
                            "body",
                        ],
                        "fuzziness": "AUTO",
                        "prefix_length": 1,
                        "max_expansions": 20,
                        "minimum_should_match": "2<75%",
                        "tie_breaker": 0.2,
                    }
                },
                # The last word as it is being typed, and short names: "mwan" finds Mwanza.
                {
                    "multi_match": {
                        "query": q,
                        "type": "bool_prefix",
                        "fields": ["headline.prefix^2", "tags.prefix", "authors.prefix", "regions.prefix"],
                    }
                },
                {"match_phrase": {"headline.exact": {"query": q, "slop": 2, "boost": 6}}},
                {"match_phrase": {"standfirst": {"query": q, "slop": 3, "boost": 2}}},
            ],
            "minimum_should_match": 1,
        }
    }


def _query(p: Params) -> dict[str, Any]:
    scored = {
        "function_score": {
            "query": _match(p.q),
            # Between 0.5 and 1.5 times: a new story wins a tie, a far better old one still comes first.
            "functions": [
                {"gauss": {"published_at": {"origin": "now", "scale": "30d", "offset": "1d", "decay": 0.5}}},
                {"weight": 0.5},
            ],
            "score_mode": "sum",
            "boost_mode": "multiply",
        }
    }
    return {"bool": {"must": [scored], "filter": _filters(p)}}


def _opensearch(p: Params) -> Page:
    after, page = _decode(p.cursor)
    sort: list[Any] = (
        [{"published_at": "desc"}, {"post_id": "asc"}]
        if p.sort == "newest"
        else [{"_score": "desc"}, {"published_at": "desc"}, {"post_id": "asc"}]
    )
    body: dict[str, Any] = {
        "size": PAGE,
        "query": _query(p),
        "sort": sort,
        "track_total_hits": 1000,
        "_source": ["card"],
        "highlight": {
            "pre_tags": [HIT],
            "post_tags": [END],
            "encoder": "default",
            "fields": {
                "standfirst": {"number_of_fragments": 0},
                "body": {"fragment_size": 160, "number_of_fragments": 1, "no_match_size": 0},
            },
        },
    }
    if after:
        body["search_after"] = after
    answer = client.call("POST", f"/{mapping.alias(p.locale)}/_search", body)
    hits = answer["hits"]["hits"]
    total = answer["hits"]["total"]
    results = []
    for h in hits:
        card = selectors.current(h["_source"]["card"])
        light = h.get("highlight", {})
        marked = (light.get("body") or light.get("standfirst") or [""])[0]
        results.append(Hit(card=card, snippet=plain_marks(segments(marked), p.q) if HIT in marked else []))
    more = len(hits) == PAGE and page < MAX_PAGES
    return Page(
        results=results,
        next_cursor=_encode(hits[-1]["sort"], page + 1) if more else None,
        total=total["value"],
        total_is_exact=total["relation"] == "eq",
        engine="opensearch",
    )


def _opensearch_suggest(q: str, locale: str) -> list[dict[str, Any]]:
    body = {
        "size": SUGGESTIONS,
        "_source": ["card.headline", "card.path", "card.type", "card.category.name"],
        "query": {
            "bool": {
                "must": [
                    {
                        "bool": {
                            "should": [
                                {
                                    "multi_match": {
                                        "query": q,
                                        "type": "bool_prefix",
                                        "fields": ["headline.prefix"],
                                    }
                                },
                                {
                                    "match": {
                                        "headline": {"query": q, "fuzziness": "AUTO", "prefix_length": 1}
                                    }
                                },
                                {"match_phrase_prefix": {"headline.exact": {"query": q, "boost": 3}}},
                            ]
                        }
                    }
                ],
                "filter": [{"range": {"published_at": {"lte": "now"}}}],
            }
        },
        "sort": [{"_score": "desc"}, {"published_at": "desc"}],
    }
    answer = client.call("POST", f"/{mapping.alias(locale)}/_search", body)
    return [_suggestion(h["_source"]["card"]) for h in answer["hits"]["hits"]]


def _suggestion(card: dict[str, Any]) -> dict[str, Any]:
    return {
        "headline": card.get("headline", ""),
        "path": card.get("path", ""),
        "type": card.get("type", ""),
        "category": (card.get("category") or {}).get("name", ""),
    }


# ----------------------------------------------------------------------------------------------------
# Postgres


def _config(locale: str) -> str:
    return "english" if locale == "en" else "simple"


def _postgres_rows(p: Params) -> Any:
    rows = Publication.objects.filter(locale=p.locale, published_at__lte=timezone.now())
    if p.types:
        rows = rows.filter(type__in=p.types)
    if p.categories:
        rows = rows.filter(
            Q(category_id__in=p.categories) | Q(category__ancestors__overlap=list(p.categories))
        )
    if p.since:
        rows = rows.filter(published_at__gte=p.since)
    return rows


def _prefix_query(q: str, config: str) -> SearchQuery | None:
    words = [re.sub(r"[^\w]", "", w) for w in q.split()]
    words = [w for w in words if w]
    if not words:
        return None
    return SearchQuery(" & ".join([*words[:-1], words[-1] + ":*"]), search_type="raw", config=config)


# strict_word_similarity, word by word: "chamjo" finds "chanjo" (0.4) and "dodma" finds "Dodoma" (0.44), but
# "mpira" (football) does not find "mpya" (new, 0.22). Plain word_similarity let that through (0.5).
TYPO_THRESHOLD = 0.4


def _words(q: str, shortest: int = 1) -> list[str]:
    return [w for w in re.findall(r"\w+", q) if len(w) >= shortest]


def _headline_like(q: str) -> Q:
    """Every word of the question looks like a word of the headline (`headline %>> word`, served by the
    trigram index publication_headline_trgm). Words of three letters or fewer must be right."""
    match = Q()
    for w in _words(q, 4):
        match &= Q(headline__trigram_strict_word_similar=w)
    return match


def _fetch(rows: Any, start: int, stop: int) -> list[Publication]:
    """The typo threshold is set for this transaction only (safe behind PgBouncer's transaction pooling)."""
    alias = rows.db
    with transaction.atomic(using=alias):
        with connections[alias].cursor() as cursor:
            cursor.execute("SET LOCAL pg_trgm.strict_word_similarity_threshold = %s", [TYPO_THRESHOLD])
        return list(rows[start:stop])


# ts_rank weights for D, C, B, A: the headline (A) counts ten times the body (C); tags, writers and the
# section (B) count little, so a story about the words comes before one only filed under them.
WEIGHTS = [0.01, 0.1, 0.2, 1.0]


def _in_headline(q: str) -> Any:
    """How many of the words begin a word of the headline: the strongest sign a story is about them."""
    total: Any = Value(0)
    for w in _words(q, 2)[:8]:
        total = total + Case(When(headline__iregex=r"\m" + re.escape(w), then=Value(1)), default=Value(0))
    return total


def _postgres(p: Params) -> Page:
    config = _config(p.locale)
    # Every word must be there (websearch: "a b" is a AND b; "a or b" and "-a" as people write them).
    words = SearchQuery(p.q, search_type="websearch", config=config)
    prefix = _prefix_query(p.q, config)
    text = Q(search_vector=words)
    text_rank: Any = Coalesce(SearchRank(F("search_vector"), words, weights=WEIGHTS), Value(0.0))
    if prefix is not None:
        # The last word as it is being typed: "mwan" finds Mwanza.
        text |= Q(search_vector=prefix)
        text_rank = text_rank + Coalesce(SearchRank(F("search_vector"), prefix, weights=WEIGHTS), Value(0.0))
    base = _postgres_rows(p).annotate(headline=KeyTextTransform("headline", "card"))
    # Look-alikes (typing mistakes) only when the words as typed find nothing at all.
    typo = _words(p.q, 4) and not base.filter(text).exists()
    match = _headline_like(p.q) if typo else text
    rank: Any = text_rank * 4 + _in_headline(p.q) * 2
    if typo:
        rank = rank + TrigramWordSimilarity(p.q, F("headline"))
    rows = base.filter(match).annotate(rank=rank).only("card", "article", "modified_at")
    rows = (
        rows.order_by("-published_at", "post_id")
        if p.sort == "newest"
        else rows.order_by("-rank", "-published_at", "post_id")
    )
    _, page = _decode(p.cursor)
    start = (page - 1) * PAGE
    chunk = _fetch(rows, start, start + PAGE + 1)
    more = len(chunk) > PAGE and page < MAX_PAGES
    return Page(
        results=[Hit(card=selectors.card(r), snippet=snippet(r, p.q)) for r in chunk[:PAGE]],
        next_cursor=_encode([], page + 1) if more else None,
        total=start + len(chunk[:PAGE]) + (1 if more else 0),
        total_is_exact=not more,
        engine="fallback",
    )


SNIPPET = 180  # characters around the first word found


def snippet(row: Publication, q: str) -> list[dict[str, Any]]:
    """Where the words are: the sentence of the standfirst or the body with most of them, the words marked;
    else the tag or writer they matched, so a reader sees why the story came. Text, never markup."""
    from newsplatform.search.documents import body_text

    words = _words(_fold(q), 2)
    if not words:
        return []

    def hit(token: str) -> bool:
        folded = _fold(token)
        return any(folded.startswith(w) for w in words)

    def hits(text: str) -> int:
        return sum(1 for t in re.findall(r"\w+", text) if hit(t))

    sentences = [
        x.strip()
        for text in (str(row.card.get("standfirst", "")), body_text(row.article))
        for x in re.split(r"(?<=[.!?])\s+", text)
        if x.strip()
    ]
    names = [
        str(i.get("name", ""))
        for key in ("tags", "regions")
        for i in (row.article.get(key) or [])
        if isinstance(i, dict)
    ] + [str(a.get("name", "")) for a in (row.card.get("authors") or []) if isinstance(a, dict)]
    best = max(sentences, key=hits, default="")
    if hits(best) == 0:
        # Found by the headline itself: the card says it already.
        if hits(str(row.card.get("headline", ""))):
            return []
        best = " · ".join(n for n in names if hits(n))
    if not best:
        return []
    first = next((m.start() for m in re.finditer(r"\w+", best) if hit(m.group())), 0)
    begin = max(0, first - SNIPPET // 3)
    if begin:
        begin = best.find(" ", begin) + 1 or begin
    cut = best[begin : begin + SNIPPET]
    if begin + SNIPPET < len(best):
        cut = cut[: cut.rfind(" ")] if " " in cut else cut
    marked = re.sub(r"\w+", lambda m: f"{HIT}{m.group()}{END}" if hit(m.group()) else m.group(), cut)
    parts = segments(("… " if begin else "") + marked + ("…" if begin + len(cut) < len(best) else ""))
    return parts


def _postgres_suggest(q: str, locale: str) -> list[dict[str, Any]]:
    """Headlines for the words typed so far: those holding them first, then look-alikes of a mistyped word."""
    prefix = _prefix_query(q, "simple")
    if prefix is None:
        return []
    base = Publication.objects.filter(locale=locale, published_at__lte=timezone.now()).annotate(
        headline=KeyTextTransform("headline", "card")
    )
    match = Q(search_vector=prefix)
    if _words(q, 4) and not base.filter(match).exists():
        match = _headline_like(q)
    rows = (
        base.filter(match)
        .annotate(
            in_headline=_in_headline(q),
            similarity=TrigramWordSimilarity(q, F("headline")),
        )
        .order_by("-in_headline", "-similarity", "-published_at")
        .only("card", "modified_at")
    )
    return [_suggestion(r.card) for r in _fetch(rows, 0, SUGGESTIONS)]


# ---------------------------------------------------------------------------------------------------- the one
# door


def search(p: Params) -> Page:
    if client.configured():
        try:
            return _opensearch(p)
        except client.EngineError as e:
            log.warning("search fell back to Postgres", extra={"reason": str(e)[:200]})
    return _postgres(p)


def suggest(q: str, locale: str) -> list[dict[str, Any]]:
    if client.configured():
        try:
            return _opensearch_suggest(q, locale)
        except client.EngineError as e:
            log.warning("suggest fell back to Postgres", extra={"reason": str(e)[:200]})
    return _postgres_suggest(q, locale)
