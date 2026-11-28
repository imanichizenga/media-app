from typing import Any

from celery import shared_task

BATCH = 500


@shared_task
def new_story(post_id: str) -> int:
    """Queued once, when a story is first published: each language's subscribers hear of it in theirs."""
    from newsplatform.notifications import services
    from newsplatform.notifications.models import Notice, PushSubscription

    if not services.enabled() or Notice.objects.filter(post_id=post_id).exists():
        return 0
    queued = 0
    for locale in ("sw", "en"):
        payload = services.message(post_id, locale)
        if payload is None:
            continue
        ids = [str(i) for i in PushSubscription.objects.filter(locale=locale).values_list("pk", flat=True)]
        for start in range(0, len(ids), BATCH):
            send_batch.delay(ids[start : start + BATCH], payload)
            queued += len(ids[start : start + BATCH])
    return queued


@shared_task(max_retries=0)
def send_batch(ids: list[str], payload: dict[str, Any]) -> int:
    from newsplatform.notifications import services

    return services.send_batch(ids, payload)


@shared_task
def notice_pushed(notice_id: str) -> int:
    """A notice in the bell also lights up the devices of its language that asked."""
    from newsplatform.notifications import services
    from newsplatform.notifications.models import Notice, PushSubscription

    row = Notice.objects.filter(pk=notice_id).first()
    if row is None or not services.enabled_push():
        return 0
    from newsplatform.site_config.services import public_config

    payload = {
        "title": row.title
        if row.kind == "notice"
        else (public_config()["identity"].get("brand_name") or "News"),
        "body": row.body if row.kind == "notice" else row.title,
        "url": row.url or "/",
        "tag": f"notice-{row.pk}",
        "image": row.image,
    }
    ids = [str(i) for i in PushSubscription.objects.filter(locale=row.locale).values_list("pk", flat=True)]
    for start in range(0, len(ids), BATCH):
        send_batch.delay(ids[start : start + BATCH], payload)
    return len(ids)
