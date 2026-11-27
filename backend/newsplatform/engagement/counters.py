"""The counts readers see (SPEC 9.6.1): one Redis hash per post, changed only when a row really changed.

A missing hash is rebuilt from the rows; `reconcile` (hourly) rebuilds the busiest ones, so a lost increment
never
lasts. Redis down: the rows are counted directly, slower but right.
"""

import contextlib
from typing import Any

import redis
from django.db.models import Count, Q

from newsplatform.common.redis import cache

FIELDS = ("likes", "comments", "bookmarks", "views")
_TTL = 7 * 86400


def _key(post_id: Any) -> str:
    return f"eng:{{{post_id}}}"


def _count(post_ids: list[str]) -> dict[str, dict[str, int]]:
    from newsplatform.content.models import Post
    from newsplatform.engagement.models import CommentStatus, PostStats

    rows = Post.objects.filter(pk__in=post_ids).annotate(
        n_likes=Count("likes", distinct=True),
        n_bookmarks=Count("bookmarks", distinct=True),
        n_comments=Count("comments", filter=Q(comments__status=CommentStatus.VISIBLE), distinct=True),
    )
    # Views are not rows: they come back from the last totals saved.
    views = dict(PostStats.objects.filter(post_id__in=list[Any](post_ids)).values_list("pk", "views"))
    return {
        str(r.pk): {
            "likes": r.n_likes,
            "comments": r.n_comments,
            "bookmarks": r.n_bookmarks,
            "views": int(views.get(r.pk, 0)),
        }
        for r in rows
    }


def get(post_ids: list[str]) -> dict[str, dict[str, int]]:
    out: dict[str, dict[str, int]] = {}
    missing: list[str] = []
    try:
        pipe = cache().pipeline(transaction=False)
        for pid in post_ids:
            pipe.hgetall(_key(pid))
        for pid, row in zip(post_ids, pipe.execute(), strict=True):
            if row:
                out[pid] = {f: int(row.get(f, 0)) for f in FIELDS}
            else:
                missing.append(pid)
    except redis.RedisError:
        return _count(post_ids)
    if missing:
        fresh = _count(missing)
        try:
            pipe = cache().pipeline(transaction=False)
            for pid, values in fresh.items():
                pipe.hset(_key(pid), mapping=values)
                pipe.expire(_key(pid), _TTL)
            pipe.execute()
        except redis.RedisError:
            pass
        out.update(fresh)
    return out


_BUMP = """
if redis.call('EXISTS', KEYS[1]) == 1 then
  local v = redis.call('HINCRBY', KEYS[1], ARGV[1], ARGV[2])
  if v < 0 then redis.call('HSET', KEYS[1], ARGV[1], 0) end
  return 1
end
return 0
"""


def bump(post_id: Any, field: str, by: int) -> None:
    """Only an existing hash moves; a missing one is rebuilt from the rows when next read."""
    with contextlib.suppress(redis.RedisError):
        cache().eval(_BUMP, 1, _key(post_id), field, by)


def forget(post_id: Any) -> None:
    with contextlib.suppress(redis.RedisError):
        cache().delete(_key(post_id))


def reconcile(post_ids: list[str]) -> int:
    """The counted rows written over the hashes. Views are left alone: not rows (engagement.views)."""
    fresh = _count(post_ids)
    try:
        pipe = cache().pipeline(transaction=False)
        for pid, values in fresh.items():
            values = {k: v for k, v in values.items() if k != "views"}
            pipe.hset(_key(pid), mapping=values)
            pipe.expire(_key(pid), _TTL)
        pipe.execute()
    except redis.RedisError:
        return 0
    return len(fresh)
