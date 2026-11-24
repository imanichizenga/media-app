from datetime import timedelta

import pytest
from django.utils import timezone

from newsplatform.approvals.models import ApprovalRequest
from newsplatform.approvals.tasks import expire_requests
from newsplatform.audit.models import AuditEntry
from newsplatform.integrations.models import IntegrationConfig, IntegrationTestRun, IntegrationVersion
from newsplatform.rbac.models import RoleAssignment
from newsplatform.site_config.models import SettingsSection
from newsplatform.site_config.schemas import Security
from tests.test_integrations import save

pytestmark = pytest.mark.django_db


@pytest.fixture
def four_eyes(db):
    SettingsSection.objects.create(key="security", data={"four_eyes": "on"}, version=1)


def _pending(api):
    save(api)
    v = IntegrationVersion.objects.get()
    IntegrationTestRun.objects.create(version=v, status="passed", finished_at=timezone.now())
    res = api.post("integrations/aws_s3/versions/1/activate")
    assert res.json() == {"approval_required": True}
    return ApprovalRequest.objects.get()


def test_second_person_must_approve(four_eyes, admin_api):
    _, a = admin_api()
    req = _pending(a)
    assert IntegrationConfig.objects.get().active_version is None
    assert a.post(f"approvals/{req.pk}/approve").json()["code"] == "four_eyes"
    b_user, b = admin_api()
    assert b.post(f"approvals/{req.pk}/approve", {"note": "ok"}).status_code == 200
    assert IntegrationConfig.objects.get().active_version is not None
    entry = AuditEntry.objects.get(action="integration.activated")
    assert entry.approved_by_id == str(b_user.pk) and entry.actor_id != entry.approved_by_id
    assert b.post(f"approvals/{req.pk}/approve").json()["code"] == "approval_closed"


def test_database_itself_refuses_self_approval(four_eyes, admin_api):
    from django.db import IntegrityError, transaction

    user, a = admin_api()
    req = _pending(a)
    with pytest.raises(IntegrityError), transaction.atomic():
        ApprovalRequest.objects.filter(pk=req.pk).update(status="executed", decided_by=user)


def test_no_secret_in_the_request(four_eyes, admin_api):
    _, a = admin_api()
    assert set(_pending(a).payload) == {"version", "override_reason"}


def test_requester_who_lost_authority(four_eyes, admin_api):
    user, a = admin_api()
    req = _pending(a)
    RoleAssignment.objects.filter(user=user).delete()
    _, b = admin_api()
    assert b.post(f"approvals/{req.pk}/approve").json()["code"] == "requester_unauthorised"


def test_newer_draft_voids_the_approval(four_eyes, admin_api):
    _, a = admin_api()
    req = _pending(a)
    save(a, 1, {}, bucket="swapped-bucket")
    _, b = admin_api()
    assert b.post(f"approvals/{req.pk}/approve").json()["code"] == "stale_version"
    req.refresh_from_db()
    assert req.status == "pending"


def test_reject_cancel_expire(four_eyes, admin_api):
    _, a = admin_api()
    _, b = admin_api()
    req = _pending(a)
    assert b.post(f"approvals/{req.pk}/reject", {"note": "no"}).json()["status"] == "rejected"
    a.post("integrations/aws_s3/versions/1/activate")
    second = ApprovalRequest.objects.get(status="pending")
    assert a.post(f"approvals/{second.pk}/reject").json()["status"] == "cancelled"
    a.post("integrations/aws_s3/versions/1/activate")
    ApprovalRequest.objects.filter(status="pending").update(expires_at=timezone.now() - timedelta(hours=1))
    third = ApprovalRequest.objects.get(status="pending")
    assert b.post(f"approvals/{third.pk}/approve").json()["code"] == "approval_expired"
    assert expire_requests() == 1


def test_privileged_grant_needs_approval_and_not_by_the_beneficiary(four_eyes, admin_api, make_staff):
    _, a = admin_api()
    target = make_staff("journalist")
    assert a.post("assignments", {"user": str(target.pk), "role": "admin"}).json() == {
        "approval_required": True
    }
    assert not target.assignments.filter(role__key="admin").exists()
    assert a.post("assignments", {"user": str(target.pk), "role": "analyst"}).json() == {
        "approval_required": False
    }
    req = ApprovalRequest.objects.get()
    _, b = admin_api()
    assert b.post(f"approvals/{req.pk}/approve").status_code == 200
    assert target.assignments.filter(role__key="admin").exists()


def test_turning_four_eyes_off_needs_four_eyes(four_eyes, admin_api):
    _, a = admin_api()
    body = {"version": 1, "values": {**Security().model_dump(), "four_eyes": "off"}}
    assert a.put("settings/security", body).json()["approval_required"] is True
    assert SettingsSection.objects.get(key="security").data["four_eyes"] == "on"


def test_four_eyes_auto_means_production(settings, db):
    from newsplatform.approvals.services import is_required

    assert not is_required("integration.activate")
    settings.ENVIRONMENT = "prod"
    assert is_required("integration.activate")


# ---- settings -------------------------------------------------------------------------------------------
def put(api, key, version, **values):
    base = api.get(f"settings/{key}").json()["values"]
    return api.put(f"settings/{key}", {"version": version, "values": {**base, **values}})


def test_update_is_public_and_audited(admin_api, client):
    _, a = admin_api()
    assert put(a, "localization", 0, default_locale="en").status_code == 200
    from newsplatform.site_config.services import public_config

    assert public_config()["localization"]["default_locale"] == "en"
    entry = AuditEntry.objects.get(action="settings.updated")
    assert entry.before == {"default_locale": "sw"} and entry.after == {"default_locale": "en"}
    assert put(a, "localization", 0, default_locale="sw").json()["code"] == "stale_version"


def test_public_config_exposes_no_security_settings(db):
    from newsplatform.site_config.services import public_config

    assert set(public_config()) == {"version", "media_base_url", "identity", "theme", "localization"}


def test_admin_cannot_touch_security(admin_api):
    _, a = admin_api("admin")
    assert put(a, "security", 0, idle_timeout_minutes=60).status_code == 403


def test_mfa_cannot_be_configured_off(admin_api):
    _, a = admin_api()
    assert put(a, "security", 0, mfa_required=False).status_code == 400
    assert not [f for f in Security.model_fields if "mfa" in f]


def test_ip_allowlist_blocks_and_refuses_self_lockout(admin_api, new_api):
    _, a = admin_api()
    assert (
        put(a, "security", 0, ip_allowlist_enabled=True, ip_allowlist=["10.0.0.0/8"]).json()["code"]
        == "self_lockout"
    )
    assert put(a, "security", 0, ip_allowlist_enabled=True, ip_allowlist=["0.0.0.0/0"]).status_code == 400
    assert (
        put(a, "security", 0, ip_allowlist_enabled=True, ip_allowlist=["203.0.113.0/24"]).status_code == 200
    )
    assert a.get("integrations").status_code == 200
    assert new_api(ip="198.51.100.1").get("auth/session").json()["code"] == "ip_not_allowed"


def test_break_glass_is_audited(admin_api):
    from django.core.management import call_command

    _, a = admin_api()
    put(a, "security", 0, ip_allowlist_enabled=True, ip_allowlist=["203.0.113.0/24"])
    call_command("break_glass_disable_allowlist", reason="office IP changed")
    assert not SettingsSection.objects.get(key="security").data["ip_allowlist_enabled"]
    assert AuditEntry.objects.get(action="settings.break_glass").reason == "office IP changed"
