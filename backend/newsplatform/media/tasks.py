import hashlib
import tempfile
from datetime import timedelta
from pathlib import Path
from typing import Any

import structlog
from celery import shared_task
from django.db import transaction
from django.utils import timezone

from newsplatform.common.errors import DomainError
from newsplatform.media import images, services, transcoding
from newsplatform.media.models import Asset, AssetStatus, Kind
from newsplatform.media.scanning import NotReady, scanner
from newsplatform.media.sniff import VIDEO_TYPES, sniff
from newsplatform.media.storage import Storage, storage

log = structlog.get_logger(__name__)
_WAIT = 20
_GIVE_UP = timedelta(hours=12)


@shared_task(bind=True, max_retries=None, time_limit=4 * 3600, soft_time_limit=4 * 3600 - 60)
def process(self: Any, asset_id: str) -> None:
    """Scan, then make derivatives. Safe to run twice: every step overwrites its own output."""
    asset = Asset.objects.filter(pk=asset_id, deleted_at__isnull=True).first()
    if asset is None or asset.status not in (AssetStatus.SCANNING, AssetStatus.PROCESSING):
        return
    try:
        _process(asset)
    except NotReady:
        if timezone.now() - asset.updated_at > _GIVE_UP:
            services.failed(asset.pk, "timeout")
            return
        raise self.retry(countdown=_WAIT) from None
    except images.BadImage as exc:
        services.failed(asset.pk, exc.code, rejected=exc.code in ("unsupported_type", "too_many_pixels"))
    except transcoding.BadVideo as exc:
        services.failed(asset.pk, exc.code, exc.detail)
    except Exception as exc:
        attempts = _count_attempt(asset)
        log.warning("media_attempt_failed", asset=str(asset.pk), attempts=attempts, error=type(exc).__name__)
        if attempts >= services.MAX_ATTEMPTS:
            # The dead-letter state: visible in the library, with a retry button.
            services.failed(asset.pk, exc.code if isinstance(exc, DomainError) else "processing_failed")
            return
        raise self.retry(countdown=30 * 2**attempts) from exc


def _count_attempt(asset: Asset) -> int:
    with transaction.atomic():
        row = Asset.objects.select_for_update().get(pk=asset.pk)
        row.attempts += 1
        row.save(update_fields=["attempts", "updated_at"])
        return row.attempts


def _process(asset: Asset) -> None:
    store = storage()
    if asset.job_id:
        return _follow(store, asset)
    guard = scanner()
    # A verdict that is still pending costs one small request, not the whole file again.
    if guard.remote and not guard.is_clean(store, asset.original_key, None):
        return _infected(store, asset)
    mime = sniff(store.head(asset.original_key))
    if asset.kind == Kind.VIDEO and guard.remote:
        # The transcoder reads storage itself: gigabytes never pass through the worker.
        Asset.objects.filter(pk=asset.pk).update(status=AssetStatus.PROCESSING, mime=mime)
    else:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source"
            store.download(asset.original_key, source)
            if not guard.remote and not guard.is_clean(store, asset.original_key, source):
                return _infected(store, asset)
            with source.open("rb") as f:
                digest = hashlib.file_digest(f, "sha256").hexdigest()
            Asset.objects.filter(pk=asset.pk).update(status=AssetStatus.PROCESSING, sha256=digest, mime=mime)
            if asset.kind == Kind.IMAGE:
                services.finished(asset.pk, **_image(store, asset, source, Path(tmp)))
                return None
    if mime not in VIDEO_TYPES:
        services.failed(asset.pk, "unsupported_type", rejected=True)
        return None
    job = transcoding.transcoder().start(store, asset, transcoding.prefix_of(asset))
    Asset.objects.filter(pk=asset.pk).update(job_id=job)
    asset.job_id = job
    return _follow(store, asset)


def _infected(store: Storage, asset: Asset) -> None:
    services.failed(asset.pk, "malware", rejected=True)
    store.delete([asset.original_key])


def _image(store: Storage, asset: Asset, source: Path, tmp: Path) -> dict[str, Any]:
    out = tmp / "out"
    out.mkdir()
    made = images.process(source, out, (asset.focal_x, asset.focal_y))
    prefix = f"media/i/{asset.original_key.rsplit('/', 1)[-1]}/"
    # A new focal point changes the crops, and everything under media/ is cached for a year.
    crops = f"{prefix}{asset.focal_x}-{asset.focal_y}/"
    keys = {s: (crops if s.startswith("crop-") else prefix) + s for _, s, _ in made.files}
    for path, suffix, content_type in made.files:
        store.upload(path, keys[suffix], content_type)
    return {
        "width": made.width,
        "height": made.height,
        "blurhash": made.blurhash,
        "dominant_color": made.color,
        "outputs": {
            "variants": {f: {w: keys[s] for w, s in sizes.items()} for f, sizes in made.variants.items()},
            "crops": {name: keys[s] for name, s in made.crops.items()},
        },
    }


@shared_task(
    bind=True,
    max_retries=5,
    autoretry_for=(Exception,),
    retry_backoff=10,
    dont_autoretry_for=(images.BadImage,),
)
def recrop(self: Any, asset_id: str) -> None:
    """New crops around a new focal point. The file stays ready: readers get the old ones meanwhile."""
    asset = Asset.objects.filter(pk=asset_id, deleted_at__isnull=True, status=AssetStatus.READY).first()
    if asset is None or asset.kind != Kind.IMAGE:
        return
    store = storage()
    with tempfile.TemporaryDirectory() as tmp:
        source = Path(tmp) / "source"
        store.download(asset.original_key, source)
        values = _image(store, asset, source, Path(tmp))
    services.recropped(asset.pk, (asset.focal_x, asset.focal_y), values["outputs"])


def _follow(store: Storage, asset: Asset) -> None:
    worker = transcoding.transcoder()
    state, detail = worker.status(asset.job_id)
    if state == "running":
        raise NotReady
    if state == "failed":
        raise transcoding.BadVideo("transcode_failed", detail)
    found = worker.probe(store, asset, asset.job_id)
    asset.duration_ms = found.duration_ms
    outputs = transcoding.finish(store, asset)
    services.finished(
        asset.pk, width=found.width, height=found.height, duration_ms=found.duration_ms, outputs=outputs
    )


@shared_task
def prune() -> int:
    return services.prune()
