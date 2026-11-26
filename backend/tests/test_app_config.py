import pytest
from django.test import Client, override_settings

from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit.models import AuditEntry
from newsplatform.site_config import services

PINS = ["A" * 43 + "=", "B" * 43 + "="]


def put(api, version=0, **values):
    base = api.get("settings/app").json()["values"]
    return api.put("settings/app", {"version": version, "values": {**base, **values}})


@pytest.fixture
def public(db):
    with override_settings(ROOT_URLCONF="config.urls_public"):
        yield Client()


def test_shape_cache_and_etag(public):
    res = public.get("/api/v1/app-config")
    body = res.json()
    assert set(body) == {
        "version", "media_base_url", "versions", "maintenance", "flags", "links", "pinning", "identity",
        "theme", "localization",
    }  # fmt: skip
    assert body["flags"] == {"shorts": True, "youtube": True, "offline_saving": True}
    assert body["theme"]["key"] == "signature"
    assert "s-maxage=120" in res["Cache-Control"]
    again = public.get("/api/v1/app-config", headers={"if-none-match": res["ETag"]})
    assert again.status_code == 304


def test_change_is_public_audited_and_changes_the_version(admin_api, django_capture_on_commit_callbacks):
    _, a = admin_api()
    before = services.app_config()["version"]
    with django_capture_on_commit_callbacks() as calls:
        res = put(a, maintenance=True, maintenance_sw="Tunarudi", maintenance_en="Back soon", shorts=False)
    assert res.status_code == 200
    assert calls
    now = services.app_config()
    assert now["version"] != before
    assert now["maintenance"] == {"on": True, "sw": "Tunarudi", "en": "Back soon"}
    assert now["flags"]["shorts"] is False
    assert AuditEntry.objects.get(action="settings.updated").after["maintenance"] is True


@pytest.mark.parametrize(
    "values",
    [
        {"pinning": True, "pins": PINS[:1]},
        {"pinning": True, "pins": [PINS[0], PINS[0]]},
        {"pins": ["short"]},
        {"min_android": "1.2"},
        {"store_ios": "http://apps.apple.com/x"},
        {"link_terms": "javascript:alert(1)"},
        {"maintenance": True, "maintenance_sw": "x"},
        {"android_packages": ["Not A Package"]},
        {"android_certificates": ["AA:BB"]},
        {"ios_app_ids": ["short.app"]},
        {"unknown": 1},
    ],
)
def test_mistakes_that_would_lock_phones_out_are_refused(admin_api, values):
    _, a = admin_api()
    assert put(a, **values).status_code == 400


def test_trust_needs_four_eyes_and_the_rest_does_not(admin_api):
    _, a = admin_api()
    _, b = admin_api("super_admin")
    values = a.get("settings/security").json()["values"]
    a.put("settings/security", {"version": 0, "values": {**values, "four_eyes": "on"}})
    assert put(a, shorts=False).json()["approval_required"] is False
    assert put(a, 1, pinning=True, pins=PINS).json()["approval_required"] is True
    assert services.app_config()["pinning"] == {"enabled": False, "pins": []}
    req = ApprovalRequest.objects.get(action="settings.app_trust")
    assert a.post(f"approvals/{req.pk}/approve", {}).status_code == 403
    assert b.post(f"approvals/{req.pk}/approve", {}).status_code == 200
    assert services.app_config()["pinning"] == {"enabled": True, "pins": PINS}
    assert put(a, 2, min_android="2.0.0").json()["approval_required"] is True


def test_pins_leave_with_the_switch(admin_api):
    _, a = admin_api()
    put(a, pinning=True, pins=PINS)
    put(a, 1, pinning=False)
    assert services.app_config()["pinning"] == {"enabled": False, "pins": []}


def test_link_files(admin_api):
    _, a = admin_api()
    certificate = ":".join(["AB"] * 32)
    public = override_settings(ROOT_URLCONF="config.urls_public")
    with public:
        assert Client().get("/.well-known/assetlinks.json").json() == []
    saved = put(
        a,
        android_packages=["tz.mfano.news"],
        android_certificates=[certificate],
        ios_app_ids=["ABCDE12345.tz.mfano.news"],
    )
    assert saved.status_code == 200
    with public:
        android = Client().get("/.well-known/assetlinks.json").json()
        res = Client().get("/.well-known/apple-app-site-association")
    assert android[0]["target"]["package_name"] == "tz.mfano.news"
    assert android[0]["target"]["sha256_cert_fingerprints"] == [certificate]
    assert res["Content-Type"] == "application/json"
    details = res.json()["applinks"]["details"][0]
    assert details["appIDs"] == ["ABCDE12345.tz.mfano.news"]
    assert {"/": "/api/*", "exclude": True} in details["components"]
