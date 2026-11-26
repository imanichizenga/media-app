"""Keeping OpenSearch equal to the database (ADR-0049): one post at a time after publishing, every index at
once when the mapping changes, and an hourly comparison that repairs what drifted."""

from __future__ import annotations

import logging
import time
from collections.abc import Iterator, Sequence
from datetime import timedelta
from typing import Any
from uuid import UUID

from django.utils import timezone

from newsplatform.common.redis import cache
from newsplatform.content.models import Publication
from newsplatform.search import client, mapping, vectors
from newsplatform.search.documents import document

log = logging.getLogger(__name__)

BATCH = 500


def _rows() -> Any:
    return Publication.objects.select_related("category")


def _write(index: str, docs: list[dict[str, Any]], deletes: Sequence[str] = ()) -> int:
    lines: list[dict[str, Any]] = []
    for doc in docs:
        lines += [{"index": {"_index": index, "_id": doc["post_id"]}}, doc]
    for pk in deletes:
        lines.append({"delete": {"_index": index, "_id": pk}})
    if not lines:
        return 0
    answer = client.call("POST", "/_bulk", ndjson=lines, read=False)
    failed = [
        item
        for item in answer.get("items", [])
        for action, result in item.items()
        if result.get("status", 500) >= 300 and not (action == "delete" and result.get("status") == 404)
    ]
    if failed:
        raise client.EngineError(f"{len(failed)} of {len(answer['items'])} bulk items failed: {failed[:2]}")
    return len(docs) + len(deletes)


def sync_post(post_id: str | UUID) -> None:
    """(The Postgres vectors are written by publishing itself.) Writes the post's publications as they are
    now, and deletes the languages it no longer has. Idempotent; under a per-post lock so that two tasks for
    the same post cannot write in the wrong order."""
    with cache().lock(f"search:post:{post_id}", timeout=60, blocking_timeout=30):
        if not client.configured():
            return
        rows = list(_rows().filter(post_id=post_id))
        present = {r.locale for r in rows}
        for locale in mapping.LOCALES:
            docs = [document(r) for r in rows if r.locale == locale]
            _write(mapping.alias(locale), docs, [] if locale in present else [str(post_id)])


def create_index(locale: str) -> str:
    name = f"{mapping.alias(locale)}-v{mapping.VERSION}-{time.time_ns() // 1_000_000}"
    client.call("PUT", f"/{name}", mapping.definition(locale), read=False)
    return name


def current(locale: str) -> str | None:
    answer = client.call("GET", f"/_alias/{mapping.alias(locale)}", read=False, ok=(404,))
    if not answer or "error" in answer:
        return None
    return str(next(iter(answer)))


def _batches(locale: str) -> Iterator[list[Publication]]:
    batch: list[Publication] = []
    for row in _rows().filter(locale=locale).order_by("pk").iterator(chunk_size=BATCH):
        batch.append(row)
        if len(batch) == BATCH:
            yield batch
            batch = []
    if batch:
        yield batch


def reindex(locale: str, *, vectors_too: bool = True) -> dict[str, Any]:
    """Builds a new index, fills it, swaps the alias, repairs what changed meanwhile, drops the old one."""
    started = timezone.now()
    new = create_index(locale)
    client.call("PUT", f"/{new}/_settings", {"index": {"refresh_interval": "-1"}}, read=False)
    count = 0
    for batch in _batches(locale):
        if vectors_too:
            vectors.write(batch)
        count += _write(new, [document(r) for r in batch])
    client.call("PUT", f"/{new}/_settings", {"index": {"refresh_interval": "5s"}}, read=False)
    client.call("POST", f"/{new}/_refresh", read=False)
    old = current(locale)
    actions: list[dict[str, Any]] = [
        {"add": {"index": new, "alias": mapping.alias(locale), "is_write_index": True}}
    ]
    if old:
        actions.insert(0, {"remove": {"index": old, "alias": mapping.alias(locale)}})
    client.call("POST", "/_aliases", {"actions": actions}, read=False)
    repaired = reconcile(locale, since=started - timedelta(minutes=5))
    if old:
        client.call("DELETE", f"/{old}", read=False, ok=(404,))
    return {"index": new, "documents": count, "repaired": repaired, "previous": old}


def _indexed(locale: str, since: Any) -> dict[str, str]:
    """post_id → etag in the index, for publications since `since` (or all), through a point in time."""
    alias = mapping.alias(locale)
    pit = client.call("POST", f"/{alias}/_search/point_in_time?keep_alive=2m", read=False)["pit_id"]
    out: dict[str, str] = {}
    after: list[Any] | None = None
    try:
        while True:
            body: dict[str, Any] = {
                "size": 5000,
                "_source": ["etag"],
                "pit": {"id": pit, "keep_alive": "2m"},
                "sort": [{"post_id": "asc"}],
                "query": {"range": {"published_at": {"gte": since.isoformat()}}}
                if since
                else {"match_all": {}},
            }
            if after:
                body["search_after"] = after
            hits = client.call("POST", "/_search", body, read=False)["hits"]["hits"]
            if not hits:
                return out
            out.update({h["_id"]: h["_source"]["etag"] for h in hits})
            after = hits[-1]["sort"]
    finally:
        client.call("DELETE", "/_search/point_in_time", {"pit_id": [pit]}, read=False, ok=(404,))


def reconcile(locale: str, *, since: Any = None) -> int:
    """Writes what the index lacks or holds stale, deletes what the database no longer has; how many."""
    if not client.configured():
        return 0
    rows = _rows().filter(locale=locale)
    if since:
        rows = rows.filter(modified_at__gte=since) | _rows().filter(locale=locale, published_at__gte=since)
    want = {str(pid): etag for pid, etag in rows.values_list("post_id", "etag")}
    have = _indexed(locale, None if since is None else since)
    stale = [pid for pid, etag in want.items() if have.get(pid) != etag]
    gone = [] if since else [pid for pid in have if pid not in want]
    fixed = 0
    for start in range(0, len(stale), BATCH):
        part = list(_rows().filter(locale=locale, post_id__in=stale[start : start + BATCH]))
        fixed += _write(mapping.alias(locale), [document(r) for r in part])
    for start in range(0, len(gone), BATCH):
        fixed += _write(mapping.alias(locale), [], gone[start : start + BATCH])
    if fixed:
        log.warning(
            "search index repaired", extra={"locale": locale, "written": len(stale), "deleted": len(gone)}
        )
    return fixed
