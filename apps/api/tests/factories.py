from typing import Any

from newsplatform.accounts.models import User
from newsplatform.content import services
from newsplatform.media.models import Asset
from newsplatform.rbac.models import RoleAssignment
from newsplatform.taxonomy.models import Category, CategoryText, Tag


def category(slug: str = "habari", parent: Category | None = None, **kw: Any) -> Category:
    row = Category.objects.create(
        parent=parent,
        depth=parent.depth + 1 if parent else 1,
        ancestors=[*parent.ancestors, parent.pk] if parent else [],
        **kw,
    )
    CategoryText.objects.create(category=row, locale="sw", name=slug.title(), slug=slug)
    CategoryText.objects.create(category=row, locale="en", name=f"{slug} en", slug=f"{slug}-en")
    return row


def tag(slug: str) -> Tag:
    return Tag.objects.create(slug=slug, name_sw=slug, name_en=f"{slug} en")


def asset(kind: str = "image", status: str = "ready", **kw: Any) -> Asset:
    n = Asset.objects.count()
    base = {
        "credit": "Mfano",
        "alt_sw": "Picha",
        "alt_en": "Picture",
        "width": 1600,
        "height": 900,
        "original_key": f"o/{n}",
        "filename": f"{n}.jpg",
    }
    return Asset.objects.create(kind=kind, status=status, bytes=1, **{**base, **kw})


def body(text: str = "Aya ya kwanza.", *more: dict[str, Any]) -> dict[str, Any]:
    first = {"type": "paragraph", "id": "block-1", "content": [{"type": "text", "text": text}]}
    return {"version": 1, "blocks": [first, *more]}


def scoped(user: User, role: Any, cat: Category) -> User:
    RoleAssignment.objects.create(user=user, role=role, scope_type="category", scope_id=str(cat.pk))
    user.is_staff_member = True
    user.save()
    return user


def post(
    actor: User, cat: Category, headline: str = "Kichwa cha habari", type: str = "article", **data: Any
) -> Any:
    row = services.create(actor=actor, type=type, category=cat, locale="sw", headline=headline)
    texts = {"sw": {"headline": headline, "standfirst": "Utangulizi", "body": body()}}
    row = services.save(actor=actor, post_id=row.pk, version=row.version, data={"texts": texts, **data})
    services.release_lock(actor=actor, post_id=row.pk)
    return row


def go(actor: User, row: Any, *steps: str, **kw: Any) -> Any:
    for step in steps:
        row.refresh_from_db()
        row = services.transition(
            actor=actor, post_id=row.pk, key=step, version=row.version, note="sababu", **kw
        )
    return row
