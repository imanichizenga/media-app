from typing import Any

from django.db import IntegrityError, transaction
from django.db.models import Max

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError
from newsplatform.common.locales import Locale
from newsplatform.engagement.services import validated as validated_policy
from newsplatform.rbac import selectors as rbac
from newsplatform.seo import paths
from newsplatform.seo.services import moved, moved_prefix
from newsplatform.taxonomy.models import MAX_DEPTH, Category, CategoryText, Region, Story, Tag

_TEXT = ("name", "slug", "description", "seo_title", "seo_description")


def lock_tree() -> None:
    """Tree edits are rare and must not interleave: two moves could otherwise make a cycle."""
    with transaction.get_connection().cursor() as cur:
        cur.execute("SELECT pg_advisory_xact_lock(hashtext('taxonomy.tree'))")


def snapshot(category: Category) -> dict[str, Any]:
    return {
        "parent": str(category.parent_id) if category.parent_id else None,
        "position": category.position,
        "icon": category.icon,
        "color": category.color,
        "visibility": category.visibility,
        "engagement": category.engagement,
        "texts": {t.locale: {f: getattr(t, f) for f in _TEXT} for t in category.texts.order_by("locale")},
    }


def _check_slug(slug: str) -> None:
    if slug in paths.RESERVED:
        raise DomainError("This address is used by the website.", code="slug_reserved", slug=slug)


@transaction.atomic
def save_category(
    *,
    actor: User,
    category: Category | None,
    parent: Category | None,
    texts: dict[str, dict[str, str]],
    version: int = 0,
    icon: str = "",
    color: str = "",
    visibility: str = "public",
    engagement: dict[str, Any] | None = None,
) -> Category:
    if category is None:
        # A new root needs the permission everywhere; a new child needs it on the parent.
        rbac.require(actor, "taxonomy.manage", parent)
    else:
        rbac.require(actor, "taxonomy.manage", category)
    if not texts or set(texts) - set(Locale.values):
        raise DomainError("At least one language is required.", code="validation_error")
    policy = validated_policy(engagement or {})
    lock_tree()
    before: dict[str, Any] | None = None
    if category is None:
        position = Category.objects.filter(parent=parent).aggregate(m=Max("position"))["m"]
        if parent and parent.depth >= MAX_DEPTH:
            raise DomainError("Categories have at most three levels.", code="too_deep")
        category = Category(
            parent=parent,
            depth=parent.depth + 1 if parent else 1,
            ancestors=[*parent.ancestors, parent.pk] if parent else [],
            position=0 if position is None else position + 1,
        )
    else:
        category = Category.objects.select_for_update().get(pk=category.pk)
        if category.version != version:
            raise Conflict("Someone else changed this. Reload and try again.", code="stale_version")
        before = snapshot(category)
        category.version += 1
    category.icon, category.color, category.visibility = icon, color.lower(), visibility
    category.engagement = policy
    category.full_clean(exclude=["parent", "ancestors", "engagement"])
    category.save()
    for locale, values in texts.items():
        _save_text(category, locale, values)
    record(
        actor=actor,
        action="category.updated" if before else "category.created",
        target=category,
        label=next(iter(texts.values()))["name"],
        before=before,
        after=snapshot(category),
    )
    _republish(category, before)
    return category


def _save_text(category: Category, locale: str, values: dict[str, str]) -> None:
    data = {k: values.get(k, "").strip() for k in _TEXT}
    data["slug"] = data["slug"] or paths.slugify(data["name"])
    _check_slug(data["slug"])
    row = CategoryText.objects.filter(category=category, locale=locale).first()
    old = row.slug if row else None
    row = row or CategoryText(category=category, locale=locale)
    for key, value in data.items():
        setattr(row, key, value)
    row.full_clean(exclude=["category"], validate_unique=False, validate_constraints=False)
    try:
        with transaction.atomic():
            row.save()
    except IntegrityError as exc:
        raise Conflict("Another category uses this address.", code="slug_taken", slug=row.slug) from exc
    if old and old != row.slug:
        moved_prefix(paths.category_path(locale, old), paths.category_path(locale, row.slug))


def _republish(category: Category, before: dict[str, Any] | None) -> None:
    if before is None or before == snapshot(category):
        return
    from newsplatform.content.tasks import rebuild_category

    transaction.on_commit(lambda: rebuild_category.delay(str(category.pk)))


@transaction.atomic
def move_category(*, actor: User, category: Category, parent: Category | None, position: int) -> None:
    rbac.require(actor, "taxonomy.manage", category)
    rbac.require(actor, "taxonomy.manage", parent)
    lock_tree()
    category.refresh_from_db()
    if parent:
        parent.refresh_from_db()
        if parent.pk == category.pk or category.pk in parent.ancestors:
            raise DomainError("A category cannot be placed inside itself.", code="category_cycle")
    branch = list(Category.objects.filter(ancestors__contains=[category.pk]))
    depth = parent.depth + 1 if parent else 1
    if depth + max((c.depth for c in branch), default=category.depth) - category.depth > MAX_DEPTH:
        raise DomainError("Categories have at most three levels.", code="too_deep")
    before = snapshot(category)
    shift, cut = depth - category.depth, len(category.ancestors)
    root = [*parent.ancestors, parent.pk] if parent else []
    category.parent, category.depth, category.ancestors = parent, depth, root
    category.version += 1
    category.save()
    for child in branch:
        child.ancestors = [*root, *child.ancestors[cut:]]
        child.depth += shift
        child.save(update_fields=["ancestors", "depth", "updated_at"])
    siblings = list(Category.objects.filter(parent=parent).exclude(pk=category.pk).order_by("position", "id"))
    siblings.insert(min(position, len(siblings)), category)
    for i, sibling in enumerate(siblings):
        Category.objects.filter(pk=sibling.pk).update(position=i)
    category.refresh_from_db()
    record(
        actor=actor,
        action="category.moved",
        target=category,
        before={"parent": before["parent"], "position": before["position"]},
        after={"parent": str(parent.pk) if parent else None, "position": category.position},
    )
    _republish(category, before)


@transaction.atomic
def merge_category(*, actor: User, source: Category, target: Category) -> None:
    """Everything in `source` moves to `target`, and its addresses redirect."""
    rbac.require(actor, "taxonomy.manage", source)
    rbac.require(actor, "taxonomy.manage", target)
    lock_tree()
    if source.pk == target.pk:
        raise DomainError("Choose two different categories.", code="validation_error")
    if source.children.exists():
        raise Conflict("Move its subcategories first.", code="category_has_children")
    if _scoped_assignments(source):
        # Following the merge would hand people rights over the target.
        raise Conflict("Staff are assigned to this category. Reassign them first.", code="category_has_staff")
    from newsplatform.content.models import Post, Publication
    from newsplatform.content.tasks import rebuild_category

    Post.objects.filter(category=source).update(category=target)
    for post in Post.objects.filter(secondary_categories=source):
        post.secondary_categories.remove(source)
        if post.category_id != target.pk:
            post.secondary_categories.add(target)
    Publication.objects.filter(category=source).update(category=target)
    slugs = {t.locale: t.slug for t in target.texts.all()}
    for text in source.texts.all():
        if text.locale in slugs:
            moved_prefix(
                paths.category_path(text.locale, text.slug),
                paths.category_path(text.locale, slugs[text.locale]),
            )
    record(
        actor=actor,
        action="category.merged",
        target=target,
        before={"source": snapshot(source)},
        after={"target": str(target.pk)},
    )
    source.delete()
    transaction.on_commit(lambda: rebuild_category.delay(str(target.pk)))


def _scoped_assignments(category: Category) -> bool:
    from newsplatform.rbac.models import RoleAssignment

    return RoleAssignment.objects.filter(scope_type="category", scope_id=str(category.pk)).exists()


# ---- tags, regions, stories ------------------------------------------------------------
def _tag_state(tag: Tag) -> dict[str, Any]:
    return {k: getattr(tag, k) for k in ("slug", "name_sw", "name_en", "synonyms")}


@transaction.atomic
def save_tag(
    *,
    actor: User,
    tag: Tag | None,
    name_sw: str,
    name_en: str,
    slug: str = "",
    synonyms: list[str] | None = None,
) -> Tag:
    rbac.require(actor, "taxonomy.manage")
    before = _tag_state(tag) if tag else None
    old = tag.slug if tag else None
    tag = tag or Tag()
    tag.name_sw, tag.name_en = name_sw.strip(), name_en.strip()
    tag.slug = slug or paths.slugify(name_sw)
    tag.synonyms = sorted({s.strip().lower() for s in synonyms or [] if s.strip()})
    tag.full_clean(validate_unique=False, exclude=["merged_into", "synonyms"])
    clash = Tag.objects.filter(synonyms__overlap=[*tag.synonyms, tag.slug]).exclude(pk=tag.pk)
    if clash.exists():
        raise Conflict("Another tag already uses one of these words.", code="synonym_taken")
    try:
        with transaction.atomic():
            tag.save()
    except IntegrityError as exc:
        raise Conflict("Another tag uses this address.", code="slug_taken", slug=tag.slug) from exc
    if old and old != tag.slug:
        for locale in Locale.values:
            moved(paths.tag_path(locale, old), paths.tag_path(locale, tag.slug))
    record(
        actor=actor,
        action="tag.updated" if before else "tag.created",
        target=tag,
        label=tag.slug,
        before=before,
        after=_tag_state(tag),
    )
    return tag


@transaction.atomic
def merge_tag(*, actor: User, source: Tag, target: Tag) -> None:
    rbac.require(actor, "taxonomy.manage")
    if source.pk == target.pk or target.merged_into_id:
        raise DomainError("Choose two different, active tags.", code="validation_error")
    from newsplatform.content.models import Post
    from newsplatform.content.tasks import rebuild_posts

    posts = list(Post.objects.filter(tags=source))
    for post in posts:
        post.tags.remove(source)
        post.tags.add(target)
    source.merged_into = target
    target.synonyms = sorted(
        {*target.synonyms, *source.synonyms, source.slug, source.name_sw.lower(), source.name_en.lower()}
        - {target.slug}
    )
    source.synonyms = []
    source.save()
    target.save()
    for locale in Locale.values:
        moved(paths.tag_path(locale, source.slug), paths.tag_path(locale, target.slug))
    record(
        actor=actor,
        action="tag.merged",
        target=target,
        label=target.slug,
        before={"source": source.slug},
        after={"posts": len(posts)},
    )
    ids = [str(p.pk) for p in posts]
    transaction.on_commit(lambda: rebuild_posts.delay(ids))


@transaction.atomic
def save_story(*, actor: User, story: Story | None, **values: Any) -> Story:
    rbac.require(actor, "taxonomy.manage")
    created, old = story is None, story.slug if story else None
    story = story or Story()
    for key in ("title_sw", "title_en", "summary_sw", "summary_en", "is_active", "slug"):
        if key in values:
            setattr(story, key, values[key])
    story.slug = story.slug or paths.slugify(story.title_sw, 120)
    story.full_clean(validate_unique=False)
    if Story.objects.filter(slug=story.slug).exclude(pk=story.pk).exists():
        raise Conflict("Another story uses this address.", code="slug_taken", slug=story.slug)
    story.save()
    if old and old != story.slug:
        for locale in Locale.values:
            moved(paths.story_path(locale, old), paths.story_path(locale, story.slug))
    record(
        actor=actor,
        action="story.created" if created else "story.updated",
        target=story,
        label=story.slug,
        after={k: str(v) for k, v in values.items()},
    )
    return story


@transaction.atomic
def save_region(*, actor: User, region: Region | None, name_sw: str, name_en: str) -> Region:
    rbac.require(actor, "taxonomy.manage")
    created = region is None
    region = region or Region(slug=paths.slugify(name_sw))
    region.name_sw, region.name_en = name_sw, name_en
    region.full_clean()
    region.save()
    record(
        actor=actor,
        action="region.created" if created else "region.updated",
        target=region,
        label=region.slug,
    )
    return region
