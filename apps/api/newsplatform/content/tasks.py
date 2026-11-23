from celery import shared_task
from django.db import transaction

from newsplatform.content import publishing, services
from newsplatform.content.models import Post, Status


@shared_task
def publish_due() -> int:
    return services.publish_due()


@shared_task
def announce(tags: list[str], pages: list[str]) -> None:
    from newsplatform.seo.delivery import purge

    purge(tags, pages)


@shared_task
def rebuild_posts(ids: list[str]) -> None:
    for pk in ids:
        with transaction.atomic():
            post = Post.objects.select_for_update().filter(pk=pk, status=Status.PUBLISHED).first()
            if post:
                # Only the surroundings changed (a category name, a tag): the article text stays as published.
                publishing.refresh(post)


@shared_task
def rebuild_category(category_id: str) -> None:
    """A category, its branch and everything filed in it, in batches of 100."""
    ids = Post.objects.filter(status=Status.PUBLISHED).filter(
        category__ancestors__contains=[category_id]
    ) | Post.objects.filter(status=Status.PUBLISHED, category_id=category_id)
    batch: list[str] = []
    for pk in ids.values_list("pk", flat=True).order_by("pk").iterator(chunk_size=500):
        batch.append(str(pk))
        if len(batch) == 100:
            rebuild_posts.delay(batch)
            batch = []
    if batch:
        rebuild_posts.delay(batch)
