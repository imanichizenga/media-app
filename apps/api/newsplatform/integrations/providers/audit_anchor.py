import json
from datetime import timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from newsplatform.audit.models import AuditEntry, ChainAnchor, ChainHead
from newsplatform.common.canonical import canonical_json
from newsplatform.integrations.aws import AwsConfig, client, field, whoami
from newsplatform.integrations.base import Provider, StepFailed, Test, guarded_call, register_provider

PREFIX = "audit-anchors/"


class AnchorConfig(AwsConfig):
    bucket: str = field(
        ..., "Object Lock bucket", "Ndoo ya Object Lock", pattern=r"^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$"
    )
    retention_days: int = field(3650, "Retention (days)", "Muda wa kuhifadhi (siku)", ge=1, le=36500)


def _active() -> AnchorConfig | None:
    from newsplatform.integrations.services import get_active

    return get_active("audit_anchor", AnchorConfig)


def _put(s3: Any, config: AnchorConfig, key: str, body: bytes, days: int) -> str:
    out = s3.put_object(
        Bucket=config.bucket,
        Key=key,
        Body=body,
        ContentType="application/json",
        ChecksumAlgorithm="SHA256",
        ObjectLockMode="COMPLIANCE",
        ObjectLockRetainUntilDate=timezone.now() + timedelta(days=days),
    )
    return str(out.get("VersionId", ""))


def anchor_head() -> ChainAnchor | None:
    """Copy the chain head to WORM storage. Returns None when unconfigured or nothing is new."""
    config = _active()
    head = ChainHead.objects.filter(id=1).first()
    if config is None or head is None or not head.seq:
        return None
    if ChainAnchor.objects.filter(seq=head.seq, hash=head.hash).exists():
        return None
    now = timezone.now()
    key = f"{PREFIX}{now:%Y/%m/%d}/{head.seq:012d}.json"
    with guarded_call("audit_anchor", "put_object"):
        version = _put(
            client(config, "s3"),
            config,
            key,
            canonical_json({"seq": head.seq, "hash": head.hash, "at": now}),
            config.retention_days,
        )
    with transaction.atomic():
        return ChainAnchor.objects.create(
            seq=head.seq, hash=head.hash, bucket=config.bucket, key=key, version_id=version
        )


def verify_against_worm() -> tuple[int, list[str]]:
    """Compare with the copies in S3 and not our own anchor table, which a database attacker could rewrite."""
    config = _active()
    if config is None:
        raise StepFailed("Audit anchoring is not configured.")
    s3, checked, problems = client(config, "s3"), 0, []
    # Every version, oldest included: overwriting a key must not hide the original.
    for page in s3.get_paginator("list_object_versions").paginate(Bucket=config.bucket, Prefix=PREFIX):
        for item in page.get("Versions", []):
            raw = s3.get_object(Bucket=config.bucket, Key=item["Key"], VersionId=item["VersionId"])[
                "Body"
            ].read()
            data = json.loads(raw)
            checked += 1
            live = AuditEntry.objects.filter(seq=data["seq"]).values_list("hash", flat=True).first()
            if live != data["hash"]:
                problems.append(f"seq {data['seq']}: WORM copy does not match the database")
    return checked, problems


@register_provider
class AuditAnchorProvider(Provider[AnchorConfig]):
    key, name, category = "audit_anchor", "Audit anchor (S3 Object Lock)", "security"
    description_en = "Daily tamper-proof copy of the audit chain head."
    description_sw = "Nakala ya kila siku isiyobadilika ya kumbukumbu za ukaguzi."
    config_model = AnchorConfig

    def test(self, config: AnchorConfig, t: Test, params: dict[str, Any]) -> None:
        box: dict[str, Any] = {}
        key = f"_probe/{timezone.now():%Y%m%dT%H%M%S%f}.json"

        def credentials() -> str:
            box["s3"] = client(config, "s3")
            return whoami(config)

        def lock() -> str:
            conf = box["s3"].get_object_lock_configuration(Bucket=config.bucket)["ObjectLockConfiguration"]
            if conf.get("ObjectLockEnabled") != "Enabled":
                raise StepFailed(
                    "Object Lock is not enabled.", "Recreate the bucket with Object Lock enabled."
                )
            return "Enabled"

        def write() -> str:
            # One minute of retention: long enough to prove the lock, short enough to expire.
            box["v"] = _put(box["s3"], config, key, b"{}", 1 / 1440)  # type: ignore[arg-type]
            return key

        def immutable() -> str:
            from botocore.exceptions import ClientError

            try:
                box["s3"].delete_object(Bucket=config.bucket, Key=key, VersionId=box["v"])
            except ClientError as exc:
                if exc.response["Error"]["Code"] in {"AccessDenied", "InvalidRequest"}:
                    return "Deletion refused, as required"
                raise
            raise StepFailed("A locked object could be deleted.", "Use Object Lock in COMPLIANCE mode.")

        t.step("credentials", "Credentials", "Vitambulisho", credentials)
        t.step("lock", "Object Lock enabled", "Object Lock imewashwa", lock, needs="credentials")
        t.step("write", "Write a locked object", "Andika faili lililofungwa", write, needs="lock")
        t.step("immutable", "Deletion is refused", "Kufuta kunakataliwa", immutable, needs="write")
