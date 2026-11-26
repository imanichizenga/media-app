from celery import shared_task

from newsplatform.search import client, indexing, mapping


@shared_task(
    autoretry_for=(client.EngineError,),
    max_retries=8,
    retry_backoff=5,
    retry_backoff_max=600,
    retry_jitter=True,
)
def index_post(post_id: str) -> None:
    """Queued after every publish, refresh and withdrawal (content.publishing.changed)."""
    indexing.sync_post(post_id)


@shared_task
def reconcile() -> int:
    """Hourly: a month of each language compared by id and etag, and repaired (ADR-0049)."""
    from datetime import timedelta

    from django.utils import timezone

    since = timezone.now() - timedelta(days=31)
    return sum(indexing.reconcile(locale, since=since) for locale in mapping.LOCALES)
