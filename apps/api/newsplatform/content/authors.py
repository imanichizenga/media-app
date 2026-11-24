"""Public author pages. The account belongs to staff_security; this is only what readers see."""

from typing import Any
from urllib.parse import urlsplit
from uuid import UUID

from django.db import transaction

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import DomainError, NotFound
from newsplatform.content.models import AuthorProfile
from newsplatform.media.models import Asset, AssetStatus
from newsplatform.media.presenters import image
from newsplatform.rbac import selectors as rbac
from newsplatform.seo import paths

_TEXT = ("title_sw", "title_en", "bio_sw", "bio_en")
MAX_LINKS, MAX_EXPERTISE = 8, 12


def ensure(user: User, *, save: bool = True) -> AuthorProfile:
    found = getattr(user, "author", None)
    if found is not None:
        profile: AuthorProfile = found
        return profile
    base = paths.slugify(user.display_name, 70) or "mwandishi"
    taken = AuthorProfile.objects.filter(slug=base).exists()
    profile = AuthorProfile(user=user, slug=f"{base}-{user.pk.hex[-6:]}" if taken else base)
    if save:
        profile.save()
    return profile


def named(profile: AuthorProfile, locale: str) -> dict[str, Any]:
    """All a card shows."""
    return {
        "id": str(profile.user_id),
        "name": profile.user.display_name,
        "slug": profile.slug,
        "path": paths.author_path(locale, profile.slug),
    }


def byline(profile: AuthorProfile, locale: str) -> dict[str, Any]:
    return {
        **named(profile, locale),
        "title": profile.title_en if locale == "en" else profile.title_sw,
        "avatar": image(profile.avatar, locale) if profile.avatar else None,
    }


def public(profile: AuthorProfile, locale: str) -> dict[str, Any]:
    return {
        **byline(profile, locale),
        "bio": profile.bio_en if locale == "en" else profile.bio_sw,
        "expertise": profile.expertise,
        "links": profile.links,
    }


def _link(raw: Any) -> str:
    text = str(raw).strip()
    try:
        url = urlsplit(text)
    except ValueError:
        url = urlsplit("")
    if url.scheme != "https" or not url.hostname or url.username or len(text) > 300:
        raise DomainError("Links must be https addresses.", code="validation_error", field="links")
    return text


@transaction.atomic
def update(*, actor: User, user_id: UUID, data: dict[str, Any]) -> AuthorProfile:
    if actor.pk != user_id:
        rbac.require(actor, "staff.manage")
    user = User.objects.select_related("author").filter(pk=user_id, is_staff_member=True).first()
    if user is None:
        raise NotFound("Not found")
    profile = ensure(user)
    fields = (*_TEXT, "expertise", "links", "avatar_id")
    before = {k: getattr(profile, k) for k in fields}
    for name in _TEXT:
        if name in data:
            setattr(profile, name, str(data[name]).strip())
    if "expertise" in data:
        words = [str(w).strip() for w in data["expertise"] if str(w).strip()]
        profile.expertise = words[:MAX_EXPERTISE]
    if "links" in data:
        profile.links = [_link(x) for x in data["links"]][:MAX_LINKS]
    if "avatar" in data:
        wanted = data["avatar"]
        row = Asset.objects.filter(
            pk=wanted, kind="image", status=AssetStatus.READY, deleted_at__isnull=True
        ).first()
        if wanted and row is None:
            raise DomainError("This file cannot be used here.", code="wrong_asset_kind")
        profile.avatar = row if wanted else None
    profile.full_clean(exclude=["user", "avatar", "expertise", "links"], validate_unique=False)
    profile.save()
    after = {k: getattr(profile, k) for k in fields}
    if after == before:
        return profile
    record(
        actor=actor,
        action="author.updated",
        target=profile,
        label=user.display_name,
        before={k: before[k] for k in fields if before[k] != after[k]},
        after={k: after[k] for k in fields if before[k] != after[k]},
    )
    from newsplatform.content.tasks import rebuild_author

    transaction.on_commit(lambda: rebuild_author.delay(str(user.pk)))
    return profile
