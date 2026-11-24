"""Uploads go straight to storage. The API only signs, checks and records."""

import math
import secrets
from datetime import timedelta
from typing import Any
from uuid import UUID

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.media.models import Asset, AssetStatus, Kind
from newsplatform.media.storage import storage
from newsplatform.rbac import selectors as rbac
from newsplatform.realtime.publish import changed

LIMITS = {Kind.IMAGE: 60 * 1024**2, Kind.VIDEO: 8 * 1024**3}
MIN_PART, MAX_PARTS, SIGN_BATCH = 8 * 1024**2, 9000, 50
MAX_ATTEMPTS = 3
_EDITABLE = ("alt_sw", "alt_en", "credit", "license", "focal_x", "focal_y")


def part_count(asset: Asset) -> int:
    return math.ceil(asset.bytes / asset.part_size)


def _part_length(asset: Asset, number: int) -> int:
    return min(asset.part_size, asset.bytes - (number - 1) * asset.part_size)


def begin_upload(*, actor: User, kind: str, filename: str, size: int) -> Asset:
    rbac.require(actor, "media.upload")
    if kind not in LIMITS:
        raise DomainError("Unknown kind", code="validation_error")
    if not 0 < size <= LIMITS[Kind(kind)]:
        raise DomainError("The file is too large.", code="file_too_large", limit=LIMITS[Kind(kind)])
    key = f"originals/{secrets.token_hex(20)}"
    upload_id = storage().begin(key)
    with transaction.atomic():
        asset = Asset.objects.create(
            kind=kind,
            filename=filename.replace("\\", "/").rsplit("/", 1)[-1][:200],
            original_key=key,
            upload_id=upload_id,
            part_size=max(MIN_PART, math.ceil(size / MAX_PARTS)),
            bytes=size,
            uploaded_by=actor,
        )
        record(
            actor=actor,
            action="media.upload_started",
            target=asset,
            label=asset.filename,
            after={"bytes": size},
        )
    return asset


def _mine(actor: User, asset_id: UUID, *, lock: bool = False) -> Asset:
    rows = Asset.objects.select_for_update() if lock else Asset.objects
    asset = rows.filter(pk=asset_id, deleted_at__isnull=True).first()
    if asset is None or asset.uploaded_by_id != actor.pk:
        raise NotFound("Not found")
    if asset.status != AssetStatus.UPLOADING:
        raise Conflict("This upload has finished.", code="upload_finished")
    return asset


def sign_parts(*, actor: User, asset_id: UUID, numbers: list[int]) -> dict[int, str]:
    asset = _mine(actor, asset_id)
    if not numbers or len(numbers) > SIGN_BATCH or not all(1 <= n <= part_count(asset) for n in numbers):
        raise DomainError("Invalid part numbers", code="validation_error")
    store = storage()
    return {
        n: store.sign_part(asset.original_key, asset.upload_id, n, _part_length(asset, n)) for n in numbers
    }


def uploaded_parts(*, actor: User, asset_id: UUID) -> list[int]:
    """What a client that lost its connection, or its tab, does not need to send again."""
    asset = _mine(actor, asset_id)
    found = storage().parts(asset.original_key, asset.upload_id)
    return [p["PartNumber"] for p in found if p["Size"] == _part_length(asset, p["PartNumber"])]


@transaction.atomic
def complete_upload(*, actor: User, asset_id: UUID) -> Asset:
    asset = _mine(actor, asset_id, lock=True)
    store = storage()
    parts = store.parts(asset.original_key, asset.upload_id)
    if sum(p["Size"] for p in parts) != asset.bytes or len(parts) != part_count(asset):
        raise Conflict("Some parts are missing.", code="parts_missing")
    store.complete(asset.original_key, asset.upload_id, parts)
    asset.status, asset.upload_id = AssetStatus.SCANNING, ""
    asset.save()
    _queue(asset)
    return asset


@transaction.atomic
def cancel_upload(*, actor: User, asset_id: UUID) -> None:
    asset = _mine(actor, asset_id, lock=True)
    storage().abort(asset.original_key, asset.upload_id)
    record(actor=actor, action="media.upload_cancelled", target=asset, label=asset.filename)
    asset.delete()


def ingest(*, actor: User, kind: str, filename: str, data: bytes, **details: Any) -> Asset:
    """Bytes we fetched ourselves, e.g. a video's thumbnail. From here on the same pipeline as any upload."""
    rbac.require(actor, "media.upload")
    if not 0 < len(data) <= LIMITS[Kind(kind)]:
        raise DomainError("The file is too large.", code="file_too_large", limit=LIMITS[Kind(kind)])
    key = f"originals/{secrets.token_hex(20)}"
    storage().put(key, data)
    with transaction.atomic():
        asset = Asset.objects.create(
            kind=kind,
            status=AssetStatus.SCANNING,
            filename=filename[:200],
            original_key=key,
            bytes=len(data),
            uploaded_by=actor,
            **details,
        )
        record(actor=actor, action="media.imported", target=asset, label=asset.filename)
        _queue(asset)
    return asset


def _queue(asset: Asset) -> None:
    from newsplatform.media.tasks import process

    pk = str(asset.pk)
    changed("asset", asset.pk)
    transaction.on_commit(lambda: process.delay(pk))


@transaction.atomic
def retry(*, actor: User, asset_id: UUID) -> Asset:
    rbac.require(actor, "media.upload")
    asset = Asset.objects.select_for_update().filter(pk=asset_id, deleted_at__isnull=True).first()
    if asset is None:
        raise NotFound("Not found")
    if asset.uploaded_by_id != actor.pk:
        rbac.require(actor, "media.manage")
    if asset.status != AssetStatus.FAILED:
        raise Conflict("Only a failed file can be retried.", code="not_retryable")
    asset.status, asset.attempts, asset.run = AssetStatus.SCANNING, 0, asset.run + 1
    asset.error_code = asset.error_detail = asset.job_id = ""
    asset.save()
    record(actor=actor, action="media.retried", target=asset, label=asset.filename)
    _queue(asset)
    return asset


@transaction.atomic
def update(*, actor: User, asset_id: UUID, data: dict[str, Any]) -> Asset:
    asset = Asset.objects.select_for_update().filter(pk=asset_id, deleted_at__isnull=True).first()
    if asset is None:
        raise NotFound("Not found")
    if asset.uploaded_by_id != actor.pk:
        rbac.require(actor, "media.manage")
    else:
        rbac.require(actor, "media.upload")
    before = {k: getattr(asset, k) for k in _EDITABLE}
    for name in _EDITABLE:
        if name in data:
            setattr(asset, name, data[name])
    asset.clean_fields(exclude={f.name for f in Asset._meta.fields} - set(_EDITABLE))
    if max(asset.focal_x, asset.focal_y) > 1000:
        raise DomainError("The focal point is outside the picture.", code="validation_error")
    asset.save()
    after = {k: getattr(asset, k) for k in _EDITABLE}
    diff = sorted(k for k in after if after[k] != before[k])
    if not diff:
        return asset
    record(
        actor=actor,
        action="media.updated",
        target=asset,
        label=asset.filename,
        before={k: before[k] for k in diff},
        after={k: after[k] for k in diff},
    )
    if {"focal_x", "focal_y"} & set(diff) and asset.kind == Kind.IMAGE and asset.status == AssetStatus.READY:
        from newsplatform.media.tasks import recrop

        pk = str(asset.pk)
        transaction.on_commit(lambda: recrop.delay(pk))
    else:
        _refresh_posts(asset)
    return asset


def usage(asset: Asset) -> list[UUID]:
    """Posts whose working copy or published page shows this file."""
    from newsplatform.content.models import Post

    in_body = (
        Q(texts__body__contains={"blocks": [{"asset": str(asset.pk)}]})
        | Q(texts__body__contains={"blocks": [{"items": [{"asset": str(asset.pk)}]}]})
        | Q(texts__body__contains={"blocks": [{"blocks": [{"asset": str(asset.pk)}]}]})
    )
    rows = Post.objects.filter(
        Q(hero=asset) | Q(video=asset) | Q(publications__asset_ids__contains=[asset.pk]) | in_body
    )
    return list(rows.distinct().order_by("-updated_at").values_list("pk", flat=True)[:100])


def elsewhere(asset: Asset) -> list[str]:
    """Uses outside articles, by name."""
    from newsplatform.site_config.services import identity

    current, used = identity(), []
    if asset.avatar_of.exists():
        used.append("author")
    used += [n for n in ("logo_light", "logo_dark", "favicon") if getattr(current, n) == str(asset.pk)]
    return used


def _refresh_posts(asset: Asset) -> None:
    from newsplatform.content.models import Publication
    from newsplatform.content.tasks import rebuild_posts

    ids = Publication.objects.filter(asset_ids__contains=[asset.pk]).values_list("post_id", flat=True)
    wanted = [str(i) for i in set(ids)]
    if wanted:
        transaction.on_commit(lambda: rebuild_posts.delay(wanted))


@transaction.atomic
def delete(*, actor: User, asset_id: UUID) -> None:
    """Out of sight at once; the bytes go after a grace period (`purge_deleted`)."""
    asset = Asset.objects.select_for_update().filter(pk=asset_id, deleted_at__isnull=True).first()
    if asset is None:
        raise NotFound("Not found")
    if asset.uploaded_by_id != actor.pk:
        rbac.require(actor, "media.manage")
    if usage(asset) or elsewhere(asset):
        raise Conflict("This file is in use.", code="asset_in_use")
    asset.deleted_at = timezone.now()
    asset.save(update_fields=["deleted_at", "updated_at"])
    record(actor=actor, action="media.deleted", target=asset, label=asset.filename)


# ---- called by the pipeline ------------------------------------------------
@transaction.atomic
def finished(asset_id: UUID, **values: Any) -> None:
    asset = Asset.objects.select_for_update().get(pk=asset_id)
    for name, value in values.items():
        setattr(asset, name, value)
    asset.status, asset.error_code, asset.error_detail = AssetStatus.READY, "", ""
    asset.save()
    changed("asset", asset.pk)
    _refresh_posts(asset)


@transaction.atomic
def recropped(asset_id: UUID, focal: tuple[int, int], outputs: dict[str, Any]) -> None:
    asset = Asset.objects.select_for_update().get(pk=asset_id)
    if (asset.focal_x, asset.focal_y) != focal:
        return  # moved again meanwhile: a newer task is on its way
    asset.outputs = outputs
    asset.save(update_fields=["outputs", "updated_at"])
    changed("asset", asset.pk)
    _refresh_posts(asset)


@transaction.atomic
def failed(asset_id: UUID, code: str, detail: str = "", *, rejected: bool = False) -> None:
    asset = Asset.objects.select_for_update().get(pk=asset_id)
    asset.status = AssetStatus.REJECTED if rejected else AssetStatus.FAILED
    asset.error_code, asset.error_detail = code[:60], detail[:500]
    asset.save()
    if rejected:
        record(
            actor=None,
            actor_label="media pipeline",
            action="media.rejected",
            target=asset,
            label=asset.filename,
            after={"code": code},
        )
    changed("asset", asset.pk)


def prune(now: Any = None) -> int:
    """Uploads abandoned for a day, rejected files after a week, deleted files after thirty days."""
    now = now or timezone.now()
    old = Asset.objects.filter(
        Q(status=AssetStatus.UPLOADING, created_at__lt=now - timedelta(days=1))
        | Q(status=AssetStatus.REJECTED, updated_at__lt=now - timedelta(days=7))
        | Q(deleted_at__lt=now - timedelta(days=30))
    )
    store, count = storage(), 0
    for asset in old.iterator():
        if asset.upload_id:
            store.abort(asset.original_key, asset.upload_id)
        token = asset.original_key.rsplit("/", 1)[-1]
        found = [asset.original_key]
        for prefix in (f"media/i/{token}/", f"media/v/{token}/"):
            found += store.keys(prefix)
        store.delete(found)
        asset.delete()
        count += 1
    return count
