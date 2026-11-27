import contextlib
import re
from collections.abc import Iterable
from typing import Any

from django.core.cache import cache as local
from django.db import IntegrityError, transaction
from django.db.models import F

from newsplatform.common.errors import DomainError, Forbidden, NotFound
from newsplatform.common.ratelimit import Limit, check
from newsplatform.engagement import counters
from newsplatform.engagement.policy import CommentMode, Override, Policy, resolve
from newsplatform.site_config.schemas import Engagement
from newsplatform.site_config.services import get_section


def settings() -> Engagement:
    section = get_section("engagement")[0]
    assert isinstance(section, Engagement)  # noqa: S101 (type narrowing)
    return section


def validated(raw: dict[str, Any]) -> dict[str, Any]:
    try:
        return Override.model_validate(raw).stored()
    except ValueError as exc:
        raise DomainError("The engagement settings are invalid.", code="validation_error") from exc


def resolved(overrides: Iterable[dict[str, Any]], current: Engagement | None = None) -> Policy:
    section = current or settings()
    return resolve(section.defaults, section.kill, overrides)


# ---- readers act (ADR-0050) ----
# The server decides, never the client: every action checks the post's rules as they are now (kill switches
# act at
# once), and every write is idempotent, so a double tap or a retried request changes nothing twice.

SLOW_SECONDS = 10  # between one reader's comments, everywhere
COMMENTS_HOURLY = 60


def post_of(post_id: str) -> Any:
    from newsplatform.content.models import Post, Status

    try:
        post = Post.objects.select_related("category").filter(pk=post_id, status=Status.PUBLISHED).first()
    except ValueError, DomainError:
        post = None
    if post is None:
        raise NotFound("This story is not available.")
    return post


def policy_of(post: Any) -> Policy:
    from newsplatform.taxonomy.selectors import policy_chain

    key = f"policy:{post.pk}:{post.version}"
    found = local.get(key)
    if found is None:
        found = resolved([*policy_chain(post.category), post.engagement])
        local.set(key, found, 30)
    return found  # type: ignore[no-any-return]


def _allowed(post: Any, what: str) -> Policy:
    policy = policy_of(post)
    if not getattr(policy, what):
        raise Forbidden("This is switched off for this story.", code="engagement_disabled")
    return policy


def _toggle(model: Any, field: str, user: Any, post: Any, on: bool) -> bool:
    if on:
        try:
            with transaction.atomic():
                model.objects.create(user=user, post=post)
        except IntegrityError:
            return False  # already so
        counters.bump(post.pk, field, 1)
        return True
    deleted, _ = model.objects.filter(user=user, post=post).delete()
    if deleted:
        counters.bump(post.pk, field, -1)
    return bool(deleted)


def like(user: Any, post_id: str, on: bool = True) -> dict[str, Any]:
    from newsplatform.engagement.models import Like

    post = post_of(post_id)
    _allowed(post, "likes")
    _toggle(Like, "likes", user, post, on)
    return {"liked": on, **counters.get([str(post.pk)])[str(post.pk)]}


def bookmark(user: Any, post_id: str, on: bool = True) -> dict[str, Any]:
    from newsplatform.engagement.models import Bookmark

    post = post_of(post_id)
    _allowed(post, "bookmarks")
    _toggle(Bookmark, "bookmarks", user, post, on)
    return {"bookmarked": on, **counters.get([str(post.pk)])[str(post.pk)]}


def state(user: Any, post_ids: list[str]) -> dict[str, dict[str, Any]]:
    """For each post: the counts, and what this reader did. Small and private, never cached by a CDN."""
    from newsplatform.engagement.models import Bookmark, Like

    ids = [p for p in post_ids if re.fullmatch(r"[0-9a-f-]{36}", p)][:50]
    counts = counters.get(ids)
    people = _readers(ids)
    liked = (
        set(map(str, Like.objects.filter(user=user, post_id__in=ids).values_list("post_id", flat=True)))
        if user
        else set()
    )
    kept = (
        set(map(str, Bookmark.objects.filter(user=user, post_id__in=ids).values_list("post_id", flat=True)))
        if user
        else set()
    )
    rules = policies(ids)
    return {
        pid: {
            **counts.get(pid, dict.fromkeys(counters.FIELDS, 0)),
            "readers": people.get(pid, 0),
            "liked": pid in liked,
            "bookmarked": pid in kept,
            "likes_on": pid in rules and rules[pid].likes,
            "comments_on": pid in rules and rules[pid].comments != CommentMode.CLOSED,
        }
        for pid in ids
    }


def policies(post_ids: list[str]) -> dict[str, Policy]:
    """The rules of many published posts in two queries: the posts, then every category above them."""
    from newsplatform.content.models import Post, Status
    from newsplatform.taxonomy.models import Category

    posts = list(
        Post.objects.filter(pk__in=post_ids, status=Status.PUBLISHED)
        .select_related("category")
        .only("id", "engagement", "category__id", "category__ancestors", "category__engagement")
    )
    above = {a for p in posts for a in p.category.ancestors}
    rows = dict(Category.objects.filter(pk__in=above).values_list("pk", "engagement")) if above else {}
    current = settings()
    return {
        str(p.pk): resolved(
            [*(rows.get(a, {}) for a in p.category.ancestors), p.category.engagement, p.engagement], current
        )
        for p in posts
    }


def comment(user: Any, post_id: str, body: str, parent_id: str | None = None) -> Any:
    from newsplatform.accounts.models import IdentityProvider
    from newsplatform.engagement.models import Comment, CommentStatus

    post = post_of(post_id)
    mode = policy_of(post).comments
    if mode == CommentMode.CLOSED:
        raise Forbidden("Comments are closed for this story.", code="engagement_disabled")
    if mode == CommentMode.VERIFIED and not user.identities.filter(provider=IdentityProvider.PHONE).exists():
        raise Forbidden("Only readers with a verified phone may comment here.", code="verification_required")
    text = re.sub(r"\n{3,}", "\n\n", (body or "").replace("\r", "")).strip()
    if not 1 <= len(text) <= 2000:
        raise DomainError("A comment is 1 to 2000 characters.", code="validation_error", field="body")
    check("comment-slow", str(user.pk), Limit(1, SLOW_SECONDS), fail_closed=False)
    check("comment-hour", str(user.pk), Limit(COMMENTS_HOURLY, 3600), fail_closed=False)
    parent = None
    if parent_id:
        parent = Comment.objects.filter(pk=parent_id, post=post, status=CommentStatus.VISIBLE).first()
        if parent is None:
            raise NotFound("That comment is gone.")
        parent = parent.parent or parent  # one level deep
    status = CommentStatus.HELD if mode == CommentMode.PREMODERATED else CommentStatus.VISIBLE
    with transaction.atomic():
        row = Comment.objects.create(post=post, user=user, parent=parent, body=text, status=status)
        if parent and status == CommentStatus.VISIBLE:
            Comment.objects.filter(pk=parent.pk).update(reply_count=F("reply_count") + 1)
    if status == CommentStatus.VISIBLE:
        counters.bump(post.pk, "comments", 1)
    return row


def delete_comment(user: Any, comment_id: str) -> None:
    from newsplatform.engagement.models import Comment, CommentStatus

    row = Comment.objects.filter(pk=comment_id, user=user).exclude(status=CommentStatus.REMOVED).first()
    if row is None:
        raise NotFound("That comment is gone.")
    was_visible = row.status == CommentStatus.VISIBLE
    with transaction.atomic():
        row.status = CommentStatus.REMOVED
        row.save(update_fields=["status", "updated_at"])
        if row.parent_id and was_visible:
            Comment.objects.filter(pk=row.parent_id, reply_count__gt=0).update(
                reply_count=F("reply_count") - 1
            )
    if was_visible:
        counters.bump(row.post_id, "comments", -1)


def like_comment(user: Any, comment_id: str, on: bool = True) -> int:
    from newsplatform.engagement.models import Comment, CommentLike, CommentStatus

    row = (
        Comment.objects.filter(pk=comment_id, status=CommentStatus.VISIBLE)
        .select_related("post__category")
        .first()
    )
    if row is None:
        raise NotFound("That comment is gone.")
    _allowed(row.post, "likes")
    if on:
        try:
            with transaction.atomic():
                CommentLike.objects.create(user=user, comment=row)
                Comment.objects.filter(pk=row.pk).update(like_count=F("like_count") + 1)
        except IntegrityError:
            pass
    elif CommentLike.objects.filter(user=user, comment=row).delete()[0]:
        Comment.objects.filter(pk=row.pk, like_count__gt=0).update(like_count=F("like_count") - 1)
    return int(Comment.objects.values_list("like_count", flat=True).get(pk=row.pk))


def follow(user: Any, kind: str, target: str, on: bool = True) -> bool:
    from newsplatform.engagement.models import Follow, FollowKind

    if kind not in FollowKind.values:
        raise DomainError("Unknown kind.", code="validation_error")
    if on:
        try:
            with transaction.atomic():
                Follow.objects.create(user=user, kind=kind, target=target)
        except IntegrityError, ValueError, DomainError:
            pass
        return True
    Follow.objects.filter(user=user, kind=kind, target=target).delete()
    return False


def _readers(ids: list[str]) -> dict[str, int]:
    """Distinct readers: the HyperLogLog, or the last saved total if Redis lost it (whichever is more)."""
    from newsplatform.engagement import views
    from newsplatform.engagement.models import PostStats

    live = views.readers(ids)
    saved = {
        str(k): int(v)
        for k, v in PostStats.objects.filter(post_id__in=list[Any](ids)).values_list("pk", "readers")
    }
    return {pid: max(live.get(pid, 0), saved.get(pid, 0)) for pid in ids}


def opened(user: Any, post_id: str, device: str) -> dict[str, Any]:
    """A story was opened. Guests are told apart by the random id their browser or app keeps."""
    from newsplatform.engagement import views

    post = post_of(post_id)
    if user is not None:
        who = f"u:{user.pk}"
    elif re.fullmatch(r"[A-Za-z0-9_-]{16,64}", device or ""):
        who = f"d:{device}"
    else:
        who = ""
    if who:
        views.opened(post.pk, who, user)
    return state(user, [str(post.pk)])[str(post.pk)]


def readers_of(post_id: str, cursor: str = "") -> dict[str, Any]:
    """Signed-in readers who opened the story, newest first, without those who chose to be left out."""
    from datetime import datetime

    from newsplatform.engagement.models import Reading

    post = post_of(post_id)
    rows = Reading.objects.filter(post=post, user__hide_from_readers=False).select_related("user")
    if cursor:
        with contextlib.suppress(ValueError):
            rows = rows.filter(last_at__lt=datetime.fromisoformat(cursor))
    page = list(rows.order_by("-last_at")[:31])
    total = _readers([str(post.pk)])[str(post.pk)]
    signed = Reading.objects.filter(post=post).count()
    return {
        "readers": total,
        "views": counters.get([str(post.pk)])[str(post.pk)]["views"],
        "guests": max(0, total - signed),
        "results": [
            {
                "name": r.user.display_name or r.user.username or "",
                "username": r.user.username or "",
                "initial": (r.user.display_name or r.user.username or "?")[:1].upper(),
                "at": r.last_at.isoformat(),
            }
            for r in page[:30]
        ],
        "next_cursor": page[29].last_at.isoformat() if len(page) > 30 else None,
    }
