import hashlib
from dataclasses import dataclass, field
from typing import Any

from django.db import models, transaction
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.audit.models import AuditEntry, ChainAnchor, ChainHead
from newsplatform.common import context
from newsplatform.common.canonical import canonical_json, to_plain

GENESIS = hashlib.sha256(b"newsplatform.audit.genesis.v1").hexdigest()
_HASHED = (
    "seq",
    "id",
    "occurred_at",
    "actor_id",
    "actor_label",
    "approved_by_id",
    "action",
    "target_type",
    "target_id",
    "target_label",
    "before",
    "after",
    "reason",
    "ip",
    "user_agent",
    "request_id",
)


def compute_hash(entry: AuditEntry) -> str:
    body = canonical_json({name: getattr(entry, name) for name in _HASHED})
    return hashlib.sha256(entry.prev_hash.encode() + b"\n" + body).hexdigest()


def record(
    *,
    actor: User | None,
    action: str,
    target: models.Model | None = None,
    label: str = "",
    before: Any = None,
    after: Any = None,
    reason: str = "",
    approved_by: User | None = None,
    actor_label: str = "",
) -> AuditEntry:
    """Append inside the caller's transaction, so a change and its audit entry commit or fail together."""
    if not transaction.get_connection().in_atomic_block:
        raise RuntimeError("Audit entries must be written in the transaction of the change they describe")
    ctx = context.current()

    def clean(text: str, limit: int) -> str:
        return str(to_plain(text))[:limit]

    ChainHead.objects.get_or_create(id=1, defaults={"hash": GENESIS})
    head = ChainHead.objects.select_for_update().get(id=1)
    entry = AuditEntry(
        seq=head.seq + 1,
        occurred_at=timezone.now(),
        actor_id=str(actor.pk) if actor else "",
        actor_label=clean(actor.display_name if actor else actor_label or "system", 120),
        approved_by_id=str(approved_by.pk) if approved_by else "",
        action=action,
        target_type=target._meta.label_lower if target is not None else "",
        target_id=str(target.pk) if target is not None else "",
        target_label=clean(label, 200),
        before=to_plain(before),
        after=to_plain(after),
        reason=clean(reason, 5000),
        ip=ctx.ip or "",
        user_agent=clean(ctx.user_agent, 400),
        request_id=ctx.request_id,
        prev_hash=head.hash,
    )
    entry.hash = compute_hash(entry)
    entry.save(force_insert=True)
    head.seq, head.hash = entry.seq, entry.hash
    head.save()
    return entry


@dataclass(slots=True)
class ChainReport:
    ok: bool = True
    checked: int = 0
    head_seq: int = 0
    anchors_checked: int = 0
    problems: list[dict[str, Any]] = field(default_factory=list)

    def fail(self, seq: int, problem: str) -> None:
        self.ok = False
        if len(self.problems) < 50:
            self.problems.append({"seq": seq, "problem": problem})


@transaction.atomic
def verify_chain() -> ChainReport:
    report = ChainReport()
    # A consistent snapshot: entries appended while we scan must not look like a mismatch.
    with transaction.get_connection().cursor() as cur:
        if not transaction.get_connection().savepoint_ids:
            cur.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ")
    anchors = {a.seq: a.hash for a in ChainAnchor.objects.all()}
    head = ChainHead.objects.filter(id=1).first()
    prev, expected = GENESIS, 1
    seen: set[int] = set()
    for entry in AuditEntry.objects.order_by("seq").iterator(chunk_size=2000):
        if entry.seq != expected:
            report.fail(entry.seq, "gap")
        if entry.prev_hash != prev:
            report.fail(entry.seq, "broken_link")
        if compute_hash(entry) != entry.hash:
            report.fail(entry.seq, "content_modified")
        if entry.seq in anchors:
            seen.add(entry.seq)
            report.anchors_checked += 1
            if anchors[entry.seq] != entry.hash:
                report.fail(entry.seq, "anchor_mismatch")
        prev, expected = entry.hash, entry.seq + 1
        report.checked += 1
    report.head_seq = head.seq if head else 0
    if report.head_seq != expected - 1 or (head and head.hash != prev):
        report.fail(expected - 1, "head_mismatch")
    for seq in anchors.keys() - seen:
        report.fail(seq, "anchored_entry_missing")
    return report
