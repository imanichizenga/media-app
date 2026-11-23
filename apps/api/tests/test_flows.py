import pytest
import redis

from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit import tasks as audit_tasks
from newsplatform.common import health
from newsplatform.rbac.models import Role
from newsplatform.site_config.models import SettingsSection
from newsplatform.staff_security import staff as staff_mod
from newsplatform.staff_security import tasks
from newsplatform.staff_security.models import StaffToken, TotpDevice

pytestmark = pytest.mark.django_db


@pytest.fixture
def four_eyes(db):
    SettingsSection.objects.create(key="security", data={"four_eyes": "on"}, version=1)


@pytest.fixture
def outbox(monkeypatch):
    sent = []
    monkeypatch.setattr(staff_mod, "deliver", lambda **kw: sent.append(kw) or True)
    return sent


def test_privileged_invite_waits_then_is_emailed(four_eyes, admin_api, outbox):
    _, a = admin_api()
    res = a.post("staff/invites", {"email": "new@example.test", "grants": [{"role": "admin"}]})
    assert res.status_code == 202
    assert res.json() == {"approval_required": True, "emailed": False, "link": None}
    assert not StaffToken.objects.exists()
    _, b = admin_api()
    assert b.post(f"approvals/{ApprovalRequest.objects.get().pk}/approve").status_code == 200
    assert StaffToken.objects.count() == 1 and "/invite#" in outbox[0]["text"]


def test_approved_invite_without_email_rolls_back(four_eyes, admin_api):
    _, a = admin_api()
    a.post("staff/invites", {"email": "new@example.test", "grants": [{"role": "admin"}]})
    _, b = admin_api()
    res = b.post(f"approvals/{ApprovalRequest.objects.get().pk}/approve")
    assert res.json()["code"] == "email_required"
    assert not StaffToken.objects.exists() and ApprovalRequest.objects.get().status == "pending"


def test_unprivileged_invite_needs_no_approval(four_eyes, admin_api, outbox):
    _, a = admin_api()
    res = a.post("staff/invites", {"email": "j@example.test", "grants": [{"role": "journalist"}]})
    assert res.status_code == 201 and res.json()["emailed"] and res.json()["link"] is None


def test_mfa_reset_needs_two_people(four_eyes, admin_api, outbox):
    _, a = admin_api()
    victim, _ = admin_api("journalist")
    assert a.post(f"staff/{victim.pk}/reset", {"reset_mfa": True}).status_code == 202
    assert TotpDevice.objects.filter(user=victim).exists()
    _, b = admin_api()
    assert b.post(f"approvals/{ApprovalRequest.objects.get().pk}/approve").status_code == 200
    assert "/reset#" in outbox[0]["text"]


def test_nobody_approves_their_own_mfa_reset(four_eyes, admin_api, outbox):
    _, a = admin_api()
    victim, theirs = admin_api()
    a.post(f"staff/{victim.pk}/reset", {"reset_mfa": True})
    assert theirs.post(f"approvals/{ApprovalRequest.objects.get().pk}/approve").json()["code"] == "four_eyes"


def test_role_crud(admin_api):
    _, a = admin_api()
    body = {"key": "desk", "name_en": "Desk", "name_sw": "Dawati", "permissions": ["media.upload"]}
    res = a.post("roles", body)
    assert res.status_code == 201
    rid = res.json()["id"]
    assert a.put(f"roles/{rid}", {**body, "name_en": "News desk"}).json()["name_en"] == "News desk"
    assert a.post("roles", body).json()["code"] == "role_exists"
    assert a.delete(f"roles/{rid}").status_code == 204 and not Role.objects.filter(key="desk").exists()


def test_assign_revoke_logout_invite_revoke(admin_api, make_staff):
    _, a = admin_api()
    target, theirs = admin_api("journalist")
    a.post("assignments", {"user": str(target.pk), "role": "analyst"})
    row = target.assignments.get(role__key="analyst")
    assert a.delete(f"assignments/{row.pk}").status_code == 204
    assert a.post(f"staff/{target.pk}/logout").status_code == 204
    assert theirs.get("me/security").status_code == 401
    a.post("staff/invites", {"email": "z@example.test", "grants": [{"role": "analyst"}]})
    token = StaffToken.objects.get()
    assert a.delete(f"staff/invites/{token.pk}").status_code == 204
    assert a.delete(f"staff/invites/{token.pk}").status_code == 404


def test_logout(admin_api):
    _, a = admin_api()
    assert a.delete("auth/session").status_code == 204
    assert a.get("me/security").status_code in (401, 403)


def test_filters(admin_api):
    _, a = admin_api()
    for path in (
        "audit?action=mfa&since=2020-01-01T00:00:00Z",
        "logs/auth?kind=login_complete",
        "logs/integrations?provider=aws_s3&ok=false",
        "approvals?status=pending",
    ):
        assert a.get(path).status_code == 200, path
    assert a.get("audit?since=garbage").status_code == 400
    assert a.get("logs/auth?user=garbage").status_code == 400
    assert a.get("integrations/nope").status_code == 404


def test_background_tasks(admin_api, monkeypatch):
    user, _ = admin_api()
    audit_tasks.verify_chain_task()
    audit_tasks.anchor_chain_task()
    tasks.prune()
    tasks.sync_waf_allowlist()
    tasks.send_alert(str(user.pk), "s", "t")


def test_broken_chain_raises_the_alarm(admin_api, tamper, monkeypatch):
    admin_api()
    tamper("UPDATE audit_auditentry SET action='x' WHERE seq=1")
    seen = []
    monkeypatch.setattr(audit_tasks.log, "critical", lambda *a, **k: seen.append(a[0]), raising=False)
    audit_tasks.verify_chain_task()
    assert seen == ["audit_chain_broken"]


def test_health(client, monkeypatch):
    assert client.get("/health/live").status_code == 200
    assert client.get("/health/ready").json()["status"] == "ok"

    class Down:
        def ping(self):
            raise redis.ConnectionError

    monkeypatch.setattr(health, "cache", Down)
    res = client.get("/health/ready")
    assert res.status_code == 200 and res.json()["status"] == "degraded"
