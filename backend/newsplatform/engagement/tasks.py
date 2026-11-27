from celery import shared_task


@shared_task
def reconcile_counts() -> int:
    """Hourly: the counts of the posts engaged with lately, rebuilt from the rows (SPEC 9.6.1)."""
    from datetime import timedelta

    from django.utils import timezone

    from newsplatform.engagement import counters
    from newsplatform.engagement.models import Bookmark, Comment, Like

    since = timezone.now() - timedelta(hours=2)
    ids: set[str] = set()
    for model in (Like, Bookmark, Comment):
        ids |= set(
            map(str, model.objects.filter(created_at__gte=since).values_list("post_id", flat=True)[:5000])
        )
    return counters.reconcile(sorted(ids))


@shared_task
def persist_views() -> int:
    """Every five minutes: views and readers saved from Redis (engagement.views)."""
    from newsplatform.engagement import views

    return views.persist()
