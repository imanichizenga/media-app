"""Writing. Every change goes through here: permission, lock, version, revision, audit."""

from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any
from uuid import UUID

from django.db import transaction
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.approvals import services as approvals
from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError, Forbidden, NotFound
from newsplatform.common.locales import Locale
from newsplatform.content import blocks, publishing
from newsplatform.content.models import (
    EditorialNote,
    Post,
    PostAuthor,
    PostText,
    PostType,
    Revision,
    RevisionKind,
    Status,
)
from newsplatform.content.workflow import EDITABLE_BY_AUTHOR, TRANSITIONS, Need, Transition
from newsplatform.engagement.services import validated as validated_policy
from newsplatform.media.models import Asset
from newsplatform.rbac import selectors as rbac
from newsplatform.rbac.selectors import Grants
from newsplatform.realtime.publish import changed
from newsplatform.seo import paths
from newsplatform.taxonomy.models import Category, Region, Story, Tag, Visibility

LOCK_TTL = timedelta(seconds=60)
KEEP_AUTOSAVES = 5
_TEXT_FIELDS = (
    "headline",
    "rail_title",
    "standfirst",
    "slug",
    "body",
    "seo_title",
    "seo_description",
    "focus_keyword",
    "update_note",
    "correction_note",
)
_PLAIN = (
    "type",
    "youtube_id",
    "youtube_seconds",
    "source_url",
    "is_evergreen",
    "is_sensitive",
    "content_warning",
)


# ---- permissions ------------------------------------------------------------
def is_author(user: User, post: Post) -> bool:
    return post.created_by_id == user.pk or post.bylines.filter(user=user).exists()


def can_edit(user: User, post: Post, grants: Grants | None = None) -> bool:
    grants = grants or rbac.grants_for(user)
    if grants.allows("content.edit_others", post):
        return True
    return (
        post.status in EDITABLE_BY_AUTHOR
        and grants.allows("content.edit_own", post)
        and is_author(user, post)
    )


def can_view(user: User, post: Post, grants: Grants | None = None) -> bool:
    grants = grants or rbac.grants_for(user)
    return any(
        grants.allows(p, post) for p in ("content.edit_others", "content.review", "content.publish")
    ) or (is_author(user, post))


def may(user: User, post: Post, transition: Transition, grants: Grants | None = None) -> bool:
    grants = grants or rbac.grants_for(user)
    if post.status not in transition.sources:
        return False
    match transition.need:
        case Need.OWN:
            return grants.allows("content.edit_others", post) or (
                grants.allows("content.edit_own", post) and is_author(user, post)
            )
        case Need.PUBLISH_OR_DIRECT:
            if grants.allows("content.publish", post):
                # Publishing straight from a draft skips review, whoever does it.
                return post.status != Status.DRAFT or grants.allows("content.publish_direct", post)
            return grants.allows("content.publish_direct", post) and is_author(user, post)
        case _:
            return grants.allows(transition.need.value, post)


def available(user: User, post: Post) -> list[str]:
    grants = rbac.grants_for(user)
    return [t.key for t in TRANSITIONS.values() if may(user, post, t, grants)]


# ---- reading for editors ------------------------------------------------------------
def get_for(user: User, post_id: UUID, *, lock: bool = False) -> Post:
    rows = Post.objects.select_for_update(of=("self",)) if lock else Post.objects
    post = rows.select_related("category", "story", "hero", "locked_by").filter(pk=post_id).first()
    # The same answer for "missing" and "not yours", so ids cannot be probed.
    if post is None or not can_view(user, post):
        raise NotFound("Not found")
    return post


def snapshot(post: Post) -> dict[str, Any]:
    return {
        **{name: getattr(post, name) for name in _PLAIN},
        "category": str(post.category_id),
        "secondary_categories": sorted(
            str(c) for c in post.secondary_categories.values_list("pk", flat=True)
        ),
        "tags": sorted(str(t) for t in post.tags.values_list("pk", flat=True)),
        "regions": sorted(str(r) for r in post.regions.values_list("pk", flat=True)),
        "story": str(post.story_id) if post.story_id else None,
        "hero": str(post.hero_id) if post.hero_id else None,
        "video": str(post.video_id) if post.video_id else None,
        "authors": [str(b.user_id) for b in post.bylines.all()],
        "breaking_until": post.breaking_until.isoformat() if post.breaking_until else None,
        "embargo_until": post.embargo_until.isoformat() if post.embargo_until else None,
        "live_ended_at": post.live_ended_at.isoformat() if post.live_ended_at else None,
        "engagement": post.engagement,
        "texts": {t.locale: {f: getattr(t, f) for f in _TEXT_FIELDS} for t in post.texts.order_by("locale")},
    }


# ---- lock ------------------------------------------------------------
def lock_holder(post: Post) -> User | None:
    fresh = post.locked_at and timezone.now() - post.locked_at < LOCK_TTL
    return post.locked_by if fresh else None


@transaction.atomic
def take_lock(*, actor: User, post_id: UUID, force: bool = False) -> Post:
    """A soft lock: it warns. `version` is what prevents lost updates."""
    post = get_for(actor, post_id, lock=True)
    if not can_edit(actor, post):
        raise Forbidden("You cannot edit this post.")
    holder = lock_holder(post)
    if holder and holder.pk != actor.pk:
        if not force:
            raise Conflict("Someone else is editing.", code="locked", holder=holder.display_name)
        record(
            actor=actor,
            action="post.lock_taken",
            target=post,
            before={"holder": str(holder.pk)},
            after={"holder": str(actor.pk)},
        )
    post.locked_by, post.locked_at = actor, timezone.now()
    post.save(update_fields=["locked_by", "locked_at"])
    return post


@transaction.atomic
def release_lock(*, actor: User, post_id: UUID) -> None:
    Post.objects.filter(pk=post_id, locked_by=actor).update(locked_by=None, locked_at=None)


# ---- saving ------------------------------------------------------------
@transaction.atomic
def create(*, actor: User, type: str, category: Category, locale: str, headline: str = "") -> Post:
    rbac.require(actor, "content.create", category)
    if type not in PostType.values or type == PostType.INSTAGRAM:
        raise DomainError("Unknown type", code="validation_error")
    if locale not in Locale.values:
        raise DomainError("Unknown language", code="validation_error")
    post = Post.objects.create(type=type, category=category, created_by=actor)
    PostText.objects.create(post=post, locale=locale, headline=headline[:200], body=blocks.EMPTY)
    PostAuthor.objects.create(post=post, user=actor)
    _revise(post, actor, RevisionKind.SAVE)
    record(
        actor=actor,
        action="post.created",
        target=post,
        label=headline,
        after={"type": type, "category": str(category.pk), "locale": locale},
    )
    return post


@transaction.atomic
def save(
    *, actor: User, post_id: UUID, version: int, data: dict[str, Any], autosave: bool = False, note: str = ""
) -> Post:
    post = get_for(actor, post_id, lock=True)
    if not can_edit(actor, post):
        raise Forbidden("You cannot edit this post.")
    holder = lock_holder(post)
    if holder and holder.pk != actor.pk:
        raise Conflict("Someone else is editing.", code="locked", holder=holder.display_name)
    if post.version != version:
        raise Conflict(
            "Someone else changed this. Reload and try again.", code="stale_version", version=post.version
        )
    before = snapshot(post)
    _apply(actor, post, data)
    post.version += 1
    post.locked_by, post.locked_at = actor, timezone.now()
    post.save()
    after = snapshot(post)
    if after == before and not note:
        return post
    _revise(post, actor, RevisionKind.AUTOSAVE if autosave else RevisionKind.SAVE, note, after)
    if not autosave:  # every few seconds per editor would serialise the whole newsroom on the audit chain
        changed = sorted(k for k in after if after[k] != before[k])
        record(
            actor=actor,
            action="post.saved",
            target=post,
            label=_label(post),
            before={k: before[k] for k in changed if k != "texts"},
            after={
                **{k: after[k] for k in changed if k != "texts"},
                "changed": changed,
                "version": post.version,
            },
        )
    return post


def _label(post: Post) -> str:
    text = post.texts.order_by("-locale").first()
    return text.headline[:120] if text else ""


def _one(model: Any, value: Any) -> Any:
    if not value:
        return None
    row = model.objects.filter(pk=value).first()
    if row is None:
        raise DomainError("Not found", code="unknown_reference", id=str(value))
    return row


def _many(model: Any, values: list[Any]) -> list[Any]:
    rows = {str(r.pk): r for r in model.objects.filter(pk__in=values)}
    if missing := [str(v) for v in values if str(v) not in rows]:
        raise DomainError("Not found", code="unknown_reference", id=missing[0])
    return [rows[str(v)] for v in values]


def _asset(value: Any, kind: str) -> Asset | None:
    asset: Asset | None = _one(Asset, value)
    if asset and (asset.kind != kind or asset.deleted_at):
        raise DomainError("This file cannot be used here.", code="wrong_asset_kind")
    return asset


def _apply(actor: User, post: Post, data: dict[str, Any]) -> None:
    for name in _PLAIN:
        if name in data:
            setattr(post, name, data[name])
    if "type" in data and data["type"] not in PostType.values:
        raise DomainError("Unknown type", code="validation_error")
    if "category" in data and str(data["category"]) != str(post.category_id):
        target = _one(Category, data["category"])
        if target is None or target.visibility == Visibility.ARCHIVED:
            raise DomainError("Choose an active category.", code="validation_error")
        # Moving is leaving one section and entering another: both must allow it.
        rbac.require(actor, "content.create", target)
        post.category = target
    if "story" in data:
        post.story = _one(Story, data["story"])
    if "hero" in data:
        post.hero = _asset(data["hero"], "image")
    if "video" in data:
        post.video = _asset(data["video"], "video")
    if "engagement" in data:
        post.engagement = validated_policy(data["engagement"])
    for name in ("breaking_until", "embargo_until", "live_ended_at"):
        if name in data:
            setattr(post, name, data[name])
    if "tags" in data:
        post.tags.set(_many(Tag, data["tags"]))
    if "regions" in data:
        post.regions.set(_many(Region, data["regions"]))
    if "secondary_categories" in data:
        rows = _many(Category, data["secondary_categories"])
        post.secondary_categories.set([c for c in rows if c.pk != post.category_id])
    if "authors" in data:
        _set_authors(actor, post, data["authors"])
    for locale, values in (data.get("texts") or {}).items():
        _save_text(post, locale, values)


def _set_authors(actor: User, post: Post, ids: list[Any]) -> None:
    people = _many(User, ids)
    if not people:
        raise DomainError("A post needs an author.", code="author_required")
    if any(not p.is_staff_member for p in people):
        raise DomainError("Authors must be staff.", code="validation_error")
    current = [b.user_id for b in post.bylines.all()]
    if current == [p.pk for p in people]:
        return
    # An author may edit, so adding one grants access. Only those who may edit others' work decide it.
    if not rbac.has_perm(actor, "content.edit_others", post) and {p.pk for p in people} != set(current):
        raise Forbidden("Only an editor can change the authors.", code="authors_locked")
    post.bylines.all().delete()
    PostAuthor.objects.bulk_create(PostAuthor(post=post, user=p, position=i) for i, p in enumerate(people))


def _save_text(post: Post, locale: str, values: dict[str, Any]) -> None:
    if locale not in Locale.values:
        raise DomainError("Unknown language", code="validation_error")
    row = PostText.objects.filter(post=post, locale=locale).first() or PostText(
        post=post, locale=locale, body=blocks.EMPTY
    )
    for name in _TEXT_FIELDS:
        if name in values:
            setattr(row, name, values[name] if name == "body" else str(values[name]).strip())
    row.body = blocks.validate(row.body)
    ids = blocks.asset_ids(row.body)
    found = set(Asset.objects.filter(pk__in=ids, deleted_at__isnull=True).values_list("pk", flat=True))
    if ids - found:
        raise DomainError(
            "A file in the article no longer exists.", code="unknown_asset", id=str(min(ids - found))
        )
    if row.slug:
        row.slug = paths.slugify(row.slug, 100)
        if PostText.objects.filter(locale=locale, slug=row.slug).exclude(post=post).exists():
            raise Conflict("Another post uses this address.", code="slug_taken", slug=row.slug)
    row.full_clean(exclude=["post", "body"], validate_unique=False, validate_constraints=False)
    row.save()


# ---- revisions ------------------------------------------------------------
def _revise(
    post: Post, author: User, kind: str, note: str = "", data: dict[str, Any] | None = None
) -> Revision:
    data = data or snapshot(post)
    latest = post.revisions.first()
    if kind == RevisionKind.AUTOSAVE and latest and latest.kind == kind and latest.author_id == author.pk:
        latest.snapshot = data
        latest.save(update_fields=["snapshot", "updated_at"])
        return latest
    revision = Revision.objects.create(
        post=post,
        number=latest.number + 1 if latest else 1,
        kind=kind,
        snapshot=data,
        author=author,
        note=note[:300],
    )
    if kind != RevisionKind.AUTOSAVE:
        old = post.revisions.filter(kind=RevisionKind.AUTOSAVE).values_list("pk", flat=True)[KEEP_AUTOSAVES:]
        Revision.objects.filter(pk__in=list(old)).delete()
    return revision


@transaction.atomic
def restore_revision(*, actor: User, post_id: UUID, number: int, version: int) -> Post:
    post = get_for(actor, post_id, lock=True)
    revision = post.revisions.filter(number=number).first()
    if revision is None:
        raise NotFound("Not found")
    if not can_edit(actor, post):
        raise Forbidden("You cannot edit this post.")
    if post.version != version:
        raise Conflict("Someone else changed this. Reload and try again.", code="stale_version")
    data = dict(revision.snapshot)
    # People and places are decided now, not by history: restoring must not return rights or move a post.
    for name in ("authors", "category", "type"):
        data.pop(name, None)
    for name in ("breaking_until", "embargo_until", "live_ended_at"):
        data[name] = datetime.fromisoformat(data[name]) if data.get(name) else None
    _apply(actor, post, data)
    for text in post.texts.all():
        if text.locale not in data["texts"]:
            text.delete()
    post.version += 1
    post.save()
    _revise(post, actor, RevisionKind.RESTORE, f"r{number}")
    record(actor=actor, action="post.restored", target=post, label=_label(post), after={"revision": number})
    return post


# ---- workflow ------------------------------------------------------------
_Listener = Callable[[Post, Transition, User | None], None]
_listeners: list[_Listener] = []


def on_transition(listener: _Listener) -> _Listener:
    """Notifications (M6) and others subscribe; they run after commit."""
    _listeners.append(listener)
    return listener


@transaction.atomic
def transition(
    *,
    actor: User,
    post_id: UUID,
    key: str,
    version: int,
    note: str = "",
    scheduled_at: datetime | None = None,
) -> Post:
    post = get_for(actor, post_id, lock=True)
    step = TRANSITIONS.get(key)
    if step is None:
        raise DomainError("Unknown transition", code="unknown_transition")
    if post.version != version:
        raise Conflict(
            "Someone else changed this. Reload and try again.", code="stale_version", version=post.version
        )
    if post.status not in step.sources:
        raise Conflict(
            "This is not possible from the current status.", code="invalid_transition", current=post.status
        )
    if not may(actor, post, step):
        raise Forbidden("You do not have permission to do this.", code="transition_forbidden")
    if step.note_required and len(note.strip()) < 3:
        raise DomainError("Explain why.", code="note_required")
    _run(post, step, actor, note.strip(), scheduled_at)
    return post


def _run(post: Post, step: Transition, actor: User | None, note: str, scheduled_at: datetime | None) -> None:
    now, before = timezone.now(), post.status
    if step.key in ("schedule", "publish", "republish"):
        publishing.check_ready(post)
    if step.key == "schedule":
        if scheduled_at is None or scheduled_at <= now:
            raise DomainError("Choose a time in the future.", code="invalid_schedule")
        if post.embargo_until and scheduled_at < post.embargo_until:
            raise DomainError("This is before the embargo ends.", code="embargoed")
        post.scheduled_at = scheduled_at
    if step.key in ("publish", "republish") and post.embargo_until and post.embargo_until > now:
        raise Conflict("This is under embargo.", code="embargoed", until=post.embargo_until.isoformat())
    if step.key == "publish":
        post.first_published_at = post.first_published_at or now
        # An unpublished article that returns keeps its place in time.
        post.published_at = post.published_at or now
    if step.key in ("publish", "unschedule", "request_changes"):
        post.scheduled_at = None
    post.status = step.target
    post.locked_by = post.locked_at = None  # handing it on ends the editing session
    post.version += 1
    post.save()
    if step.key in ("publish", "republish"):
        publishing.publish(post)
        _revise(post, actor or post.created_by, RevisionKind.PUBLISH)
    elif step.key == "unpublish":
        publishing.withdraw(post)
    if note and actor:
        EditorialNote.objects.create(post=post, author=actor, text=note[:2000], transition=step.key)
    record(
        actor=actor,
        actor_label="" if actor else "scheduler",
        action=f"post.{step.key}",
        target=post,
        label=_label(post),
        reason=note,
        before={"status": before},
        after={"status": post.status, "scheduled_at": post.scheduled_at},
    )
    changed("post", post.pk)
    for listener in _listeners:
        transaction.on_commit(lambda listener=listener: listener(post, step, actor), robust=True)  # type: ignore[misc]


def publish_due(now: datetime | None = None, limit: int = 100) -> int:
    """Every minute. Each post in its own transaction, so one that fails does not hold up the rest."""
    now = now or timezone.now()
    due = Post.objects.filter(status=Status.SCHEDULED, scheduled_at__lte=now).order_by("scheduled_at")
    done = 0
    for pk in list(due.values_list("pk", flat=True)[:limit]):
        try:
            with transaction.atomic():
                post = (
                    Post.objects.select_for_update(skip_locked=True)
                    .filter(pk=pk, status=Status.SCHEDULED)
                    .first()
                )
                if post is None:
                    continue
                _run(post, TRANSITIONS["publish"], None, "", None)
                done += 1
        except DomainError as exc:
            _schedule_failed(pk, exc)
    return done


@transaction.atomic
def _schedule_failed(pk: UUID, exc: DomainError) -> None:
    post = Post.objects.select_for_update().get(pk=pk)
    if post.status != Status.SCHEDULED:
        return
    post.status, post.scheduled_at = Status.APPROVED, None
    post.version += 1
    post.save()
    record(
        actor=None,
        actor_label="scheduler",
        action="post.schedule_failed",
        target=post,
        label=_label(post),
        before={"status": Status.SCHEDULED},
        after={"status": post.status, "error": exc.code},
    )


@transaction.atomic
def add_note(*, actor: User, post_id: UUID, text: str) -> EditorialNote:
    post = get_for(actor, post_id)
    if not text.strip():
        raise DomainError("Write a note.", code="validation_error")
    note = EditorialNote.objects.create(post=post, author=actor, text=text.strip()[:2000])
    record(actor=actor, action="post.note_added", target=post, label=_label(post))
    changed("post", post.pk)
    return note


# ---- live blogs, bulk ------------------------------------------------------------
@transaction.atomic
def add_live_update(
    *, actor: User, post_id: UUID, version: int, locale: str, update: dict[str, Any], publish: bool
) -> Post:
    """Newest first. With `publish`, readers see it in the same transaction."""
    post = get_for(actor, post_id, lock=True)
    if post.type != PostType.LIVE_BLOG:
        raise DomainError("Only a live blog has updates.", code="not_live_blog")
    text = post.texts.filter(locale=locale).first()
    if text is None:
        raise NotFound("Not found")
    block = {**update, "type": "live_update", "time": timezone.now().isoformat(timespec="seconds")}
    body = {**text.body, "blocks": [block, *text.body["blocks"]]}
    post = save(
        actor=actor, post_id=post_id, version=version, data={"texts": {locale: {"body": body}}}, note="live"
    )
    if publish and post.status == Status.PUBLISHED:
        post = transition(actor=actor, post_id=post_id, key="republish", version=post.version)
    return post


BULK_LIMIT, BULK_FOUR_EYES = 100, 10
BULK_ACTIONS = ("archive", "unpublish", "publish", "approve")
BULK_CHOICES = [(k, k) for k in BULK_ACTIONS]
_REMOVES = ("archive", "unpublish")


def bulk(*, actor: User, key: str, ids: list[UUID], note: str) -> list[dict[str, str]] | ApprovalRequest:
    """Each post on its own: one that cannot change does not stop the others, and says why."""
    ids = list(dict.fromkeys(ids))
    if key not in BULK_ACTIONS or not 0 < len(ids) <= BULK_LIMIT:
        raise DomainError("Invalid bulk action", code="validation_error")
    if key in _REMOVES and len(ids) >= BULK_FOUR_EYES and approvals.is_required("content.bulk_remove"):
        return approvals.request_approval(
            actor=actor,
            action="content.bulk_remove",
            summary=f"{key.capitalize()} {len(ids)} posts",
            payload={"key": key, "ids": [str(i) for i in ids], "note": note},
            dedupe_key=f"{key}:{actor.pk}",
            reason=note,
        )
    return _bulk(actor, key, ids, note)


def _bulk(actor: User, key: str, ids: list[UUID], note: str) -> list[dict[str, str]]:
    out = []
    for pk in ids:
        try:
            with transaction.atomic():
                version = get_for(actor, pk, lock=True).version
                transition(actor=actor, post_id=pk, key=key, version=version, note=note)
            out.append({"id": str(pk), "result": "ok"})
        except DomainError as exc:
            out.append({"id": str(pk), "result": exc.code})
    return out


@approvals.register("content.bulk_remove", "content.delete")
def _execute_bulk(payload: dict[str, Any], requester: User, approver: User) -> None:
    _bulk(requester, payload["key"], [UUID(i) for i in payload["ids"]], payload["note"])
