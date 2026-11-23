import pytest
from django.core.management import CommandError, call_command
from django.db import InternalError, ProgrammingError, connection, transaction

from newsplatform.audit.models import AuditEntry, ChainAnchor
from newsplatform.audit.services import record, verify_chain

pytestmark = pytest.mark.django_db


@pytest.fixture
def entries(db):
    with transaction.atomic():
        return [record(actor=None, action=f"t.{i}", after={"n": i, "jina": "Habari ñ 🙂"}) for i in range(5)]


def test_chain_links_and_verifies(entries):
    rows = list(AuditEntry.objects.order_by("seq"))
    assert [r.seq for r in rows] == [1, 2, 3, 4, 5]
    assert all(b.prev_hash == a.hash for a, b in zip(rows, rows[1:], strict=False))
    report = verify_chain()
    assert report.ok and report.checked == 5


@pytest.mark.parametrize(
    "sql",
    ["UPDATE audit_auditentry SET action='x'", "DELETE FROM audit_auditentry", "TRUNCATE audit_auditentry"],
)
def test_database_refuses_mutation(entries, sql):
    with pytest.raises((InternalError, ProgrammingError)), transaction.atomic(), connection.cursor() as cur:
        cur.execute(sql)
    assert AuditEntry.objects.count() == 5


@pytest.mark.parametrize(
    ("sql", "problem"),
    [
        ("UPDATE audit_auditentry SET actor_label='someone else' WHERE seq=3", "content_modified"),
        ("UPDATE audit_auditentry SET after='{\"n\": 99}' WHERE seq=3", "content_modified"),
        ("DELETE FROM audit_auditentry WHERE seq=3", "gap"),
        ("DELETE FROM audit_auditentry WHERE seq=5", "head_mismatch"),
    ],
)
def test_tampering_is_detected(entries, tamper, sql, problem):
    tamper(sql)
    report = verify_chain()
    assert not report.ok
    assert problem in {p["problem"] for p in report.problems}
    with pytest.raises(CommandError):
        call_command("verify_audit_chain")


def test_anchor_catches_a_fully_recomputed_chain(entries, tamper):
    """Rewriting an entry AND every later hash fools the chain alone; the anchor still catches it."""
    from newsplatform.audit.services import compute_hash

    ChainAnchor.objects.create(seq=5, hash=entries[-1].hash, bucket="b", key="k")
    prev = AuditEntry.objects.get(seq=2).hash
    for seq in (3, 4, 5):
        row = AuditEntry.objects.get(seq=seq)
        row.prev_hash = prev
        if seq == 3:
            row.actor_label = "framed"
        prev = compute_hash(row)
        tamper(
            "UPDATE audit_auditentry SET actor_label=%s, prev_hash=%s, hash=%s WHERE seq=%s",
            row.actor_label,
            row.prev_hash,
            prev,
            seq,
        )
    tamper("UPDATE audit_chainhead SET hash=%s", prev)
    assert {p["problem"] for p in verify_chain().problems} == {"anchor_mismatch"}


def test_truncated_tail_caught_by_anchor(entries, tamper):
    ChainAnchor.objects.create(seq=5, hash=entries[-1].hash, bucket="b", key="k")
    tamper("DELETE FROM audit_auditentry WHERE seq=5")
    tamper("UPDATE audit_chainhead SET seq=4, hash=%s", entries[3].hash)
    assert "anchored_entry_missing" in {p["problem"] for p in verify_chain().problems}


def test_rolls_back_with_the_change_it_describes(entries):
    with pytest.raises(ValueError, match="boom"), transaction.atomic():
        record(actor=None, action="t.lost")
        raise ValueError("boom")
    assert not AuditEntry.objects.filter(action="t.lost").exists()
    assert verify_chain().ok


def test_odd_values_survive_the_jsonb_round_trip(db):
    import datetime as dt
    import decimal
    import uuid

    with transaction.atomic():
        record(
            actor=None,
            action="odd",
            label="nul\x00",
            before={"f": 1.10, "d": decimal.Decimal("2.50")},
            after={"u": uuid.uuid4(), "t": dt.datetime.now(dt.UTC), "s": {3, 1}, "nul": "a\x00b"},
        )
    assert verify_chain().ok
