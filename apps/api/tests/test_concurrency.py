"""Real threads, real commits, real Postgres: the races that unit tests cannot see."""

import os
from concurrent.futures import ThreadPoolExecutor

import psycopg
import pytest
from django.core.management import call_command
from django.db import connection, connections, transaction

from newsplatform.audit.models import AuditEntry
from newsplatform.audit.services import record, verify_chain
from newsplatform.common.errors import DomainError
from newsplatform.staff_security import mfa, sessions
from newsplatform.staff_security.models import SessionStage, StaffSession
from newsplatform.staff_security.staff import accept_invite

pytestmark = pytest.mark.django_db(transaction=True)


@pytest.fixture(autouse=True)
def _allow_flush(transactional_db):
    """pytest truncates tables after each test; production triggers (rightly) forbid that."""
    yield
    with connection.cursor() as cur:
        for table in ("audit_auditentry", "audit_chainanchor"):
            cur.execute(f"ALTER TABLE {table} DISABLE TRIGGER USER")
            cur.execute(f"TRUNCATE {table}")
            cur.execute(f"ALTER TABLE {table} ENABLE TRIGGER USER")
        # The flush that follows also truncates; keep the statement trigger off until the next migration run.
        cur.execute("ALTER TABLE audit_auditentry DISABLE TRIGGER audit_entry_no_truncate")
        cur.execute("ALTER TABLE audit_chainanchor DISABLE TRIGGER audit_anchor_no_truncate")


def race(fn, n=12):
    def call(i):
        try:
            return fn(i)
        except Exception as exc:
            return exc
        finally:
            connections.close_all()

    with ThreadPoolExecutor(n) as pool:
        return list(pool.map(call, range(n)))


def test_parallel_appends_never_fork_the_chain(_allow_flush):
    def append(i):
        with transaction.atomic():
            record(actor=None, action=f"p.{i}")

    assert race(append, 16) == [None] * 16
    assert [e.seq for e in AuditEntry.objects.order_by("seq")] == list(range(1, 17))
    assert verify_chain().ok


def _session(user):
    from django.test import RequestFactory

    return sessions.create(user, SessionStage.MFA_CHALLENGE, RequestFactory().get("/"))[0]


def test_recovery_code_spent_once(make_staff):
    user = make_staff()
    code = mfa.generate_recovery_codes(user)[0]
    rows = [_session(user) for _ in range(8)]
    out = race(lambda i: mfa.recovery_verify(StaffSession.objects.get(pk=rows[i].pk), code) or "ok", 8)
    assert out.count("ok") == 1 and sum(isinstance(o, DomainError) for o in out) == 7


def test_totp_code_spent_once(make_staff):
    import pyotp

    user = make_staff()
    device = pyotp.TOTP(mfa.totp_begin(_session(user))["secret"])
    rows = [_session(user) for _ in range(8)]
    out = race(lambda i: mfa.totp_confirm(StaffSession.objects.get(pk=rows[i].pk), device.now()) and "ok", 8)
    assert out.count("ok") == 1


def test_invite_accepted_once(make_staff):
    from newsplatform.staff_security.staff import _create_invite

    boss = make_staff()
    with transaction.atomic():
        _, url = _create_invite(boss, "a@example.test", [{"role": "journalist"}])
    raw = url.split("#")[1]
    out = race(
        lambda i: accept_invite(raw=raw, display_name="A", password="a long enough phrase", locale="sw"), 6
    )
    assert sum(not isinstance(o, Exception) for o in out) == 1


def test_runtime_role_cannot_rewrite_history(_allow_flush, monkeypatch):
    with transaction.atomic():
        record(actor=None, action="kept")
    monkeypatch.setenv("APP_DB_USER", "news_app_test")
    monkeypatch.setenv("APP_DB_PASSWORD", "app-pass-'quoted\"")
    call_command("provision_db_roles")
    call_command("provision_db_roles")  # idempotent
    s = connection.settings_dict
    dsn = {
        "host": s["HOST"],
        "port": s["PORT"],
        "dbname": s["NAME"],
        "user": "news_app_test",
        "password": os.environ["APP_DB_PASSWORD"],
    }
    try:
        with psycopg.connect(**dsn, autocommit=True) as conn:
            assert conn.execute("SELECT count(*) FROM audit_auditentry").fetchone() == (1,)
            conn.execute("UPDATE accounts_user SET locale = 'en'")
            for sql in (
                "UPDATE audit_auditentry SET action='x'",
                "DELETE FROM audit_auditentry",
                "TRUNCATE audit_auditentry",
                "DELETE FROM audit_chainhead",
                "DELETE FROM audit_chainanchor",
                "ALTER TABLE audit_auditentry DISABLE TRIGGER ALL",
                "DROP TABLE audit_auditentry",
                "DELETE FROM django_migrations",
            ):
                with pytest.raises(psycopg.errors.InsufficientPrivilege):
                    conn.execute(sql)
    finally:
        with connection.cursor() as cur:
            cur.execute("REVOKE ALL ON ALL TABLES IN SCHEMA public FROM news_app_test")
            cur.execute("REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM news_app_test")
            cur.execute("REVOKE ALL ON SCHEMA public FROM news_app_test")
            cur.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM news_app_test")
            cur.execute(
                "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM news_app_test"
            )
            cur.execute("DROP ROLE news_app_test")
