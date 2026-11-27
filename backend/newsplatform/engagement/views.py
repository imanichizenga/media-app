"""How many times a story was opened, and by how many people (ADR-0050).

Views: every opening, but one device counts once in 30 minutes, so refreshing does not inflate it.
Readers: distinct people, counted in a HyperLogLog (12 KB per story whatever the audience, within 1%),
signed-in readers by account and guests by the random id their browser or app keeps.
Redis takes every opening; `persist` saves the totals to
PostStats every few minutes, and a lost Redis starts again from them.
"""

from typing import Any

import redis
from django.db import transaction
from django.utils import timezone

from newsplatform.common.redis import cache

_COOLDOWN = 30 * 60
_HLL_TTL = 120 * 86400
DIRTY = "eng:dirty"


def _uv(post_id: Any) -> str:
    return f"eng:uv:{{{post_id}}}"


_OPEN = """
local fresh = redis.call('SET', KEYS[3], 1, 'NX', 'EX', ARGV[2])
redis.call('PFADD', KEYS[2], ARGV[1])
redis.call('EXPIRE', KEYS[2], ARGV[3])
if fresh and redis.call('EXISTS', KEYS[1]) == 1 then redis.call('HINCRBY', KEYS[1], 'views', 1) end
redis.call('SADD', KEYS[4], ARGV[4])
return fresh and 1 or 0
"""


def opened(post_id: Any, who: str, user: Any = None) -> bool:
    """Count an opening; True when it counted as a view. `who` is "u:<id>" or "d:<device id>"."""
    from newsplatform.engagement.counters import _key, get

    get([str(post_id)])  # make sure the hash exists, rebuilt from PostStats if it was lost
    counted = False
    try:
        counted = bool(
            cache().eval(
                _OPEN,
                4,
                _key(post_id),
                _uv(post_id),
                f"eng:seen:{{{post_id}}}:{who}",
                DIRTY,
                who,
                _COOLDOWN,
                _HLL_TTL,
                str(post_id),
            )
        )
    except redis.RedisError:
        _bump_db(post_id)
        counted = True
    if user is not None:
        from newsplatform.engagement.models import Reading

        Reading.objects.update_or_create(user=user, post_id=post_id, defaults={"last_at": timezone.now()})
    return counted


def _bump_db(post_id: Any) -> None:
    from django.db.models import F

    from newsplatform.engagement.models import PostStats

    with transaction.atomic():
        PostStats.objects.get_or_create(post_id=post_id)
        PostStats.objects.filter(pk=post_id).update(views=F("views") + 1)


def readers(post_ids: list[str]) -> dict[str, int]:
    try:
        pipe = cache().pipeline(transaction=False)
        for pid in post_ids:
            pipe.pfcount(_uv(pid))
        return {pid: int(n) for pid, n in zip(post_ids, pipe.execute(), strict=True)}
    except redis.RedisError:
        return {}


def persist(limit: int = 5000) -> int:
    """Every few minutes: the totals of the stories opened since, saved."""
    from newsplatform.engagement.counters import _key
    from newsplatform.engagement.models import PostStats

    try:
        ids = [x.decode() if isinstance(x, bytes) else str(x) for x in cache().spop(DIRTY, limit) or []]
        if not ids:
            return 0
        pipe = cache().pipeline(transaction=False)
        for pid in ids:
            pipe.hget(_key(pid), "views")
            pipe.pfcount(_uv(pid))
        values = pipe.execute()
    except redis.RedisError:
        return 0
    rows = []
    for i, pid in enumerate(ids):
        views, people = values[2 * i], values[2 * i + 1]
        if views is None:
            continue
        rows.append(PostStats(post_id=pid, views=int(views), readers=int(people)))
    PostStats.objects.bulk_create(
        rows, update_conflicts=True, unique_fields=["post"], update_fields=["views", "readers", "updated_at"]
    )
    return len(rows)
