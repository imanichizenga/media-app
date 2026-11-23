from datetime import timedelta

import pytest
import redis
from django.utils import timezone

from newsplatform.accounts.models import User, UserStatus
from newsplatform.staff_security import login as login_mod
from newsplatform.staff_security.models import AuthEvent, KnownDevice, StaffSession, StaffToken
from tests.conftest import PASSWORD, UA

pytestmark = pytest.mark.django_db
COOKIE = "__Host-staff_session"


def test_password_alone_opens_nothing(api, make_staff):
    res = api.login(make_staff())
    assert res.status_code == 200
    assert res.json()["stage"] == "mfa_enroll"
    assert res.json()["permissions"] == []
    for path in ("integrations", "audit", "staff", "roles", "me/security", "settings/identity"):
        assert api.get(path).status_code == 403, path


def test_cookie_flags(api, make_staff):
    c = api.login(make_staff()).cookies[COOKIE]
    assert (
        c["httponly"] and c["secure"] and c["samesite"] == "Strict" and c["path"] == "/" and not c["domain"]
    )


def test_enrol_then_use(api, make_staff):
    api.sign_in(make_staff())
    assert len(api.codes) == 10
    assert api.get("auth/session").json()["stage"] == "active"
    assert api.get("integrations").status_code == 200


def test_token_rotates_on_promotion_and_old_one_dies(api, make_staff, new_api):
    api.login(make_staff())
    old = api.client.cookies[COOKIE].value
    api.enrol_totp()
    assert api.client.cookies[COOKIE].value != old
    thief = new_api()
    thief.client.cookies[COOKIE] = old
    assert thief.get("auth/session").status_code in (401, 403)


def test_half_open_session_cannot_enrol_over_existing_mfa(make_staff, new_api):
    """Attacker with only the password must not add their own authenticator."""
    user = make_staff()
    new_api().sign_in(user)
    thief = new_api()
    assert thief.login(user).json()["stage"] == "mfa_challenge"
    for path in ("totp/begin", "passkey/register/options"):
        assert thief.post(f"auth/mfa/{path}").status_code == 403


def test_stale_enrol_session_blocked_once_mfa_exists(make_staff, new_api):
    """Two enrol-stage sessions: finishing one must close the door for the other."""
    user = make_staff()
    thief, owner = new_api(), new_api()
    thief.login(user)
    owner.sign_in(user)
    assert thief.post("auth/mfa/totp/begin").json()["code"] == "mfa_exists"


def test_totp_code_is_single_use(make_staff, new_api):
    user = make_staff()
    first = new_api().sign_in(user)
    second = new_api()
    second.login(user)
    assert second.post("auth/mfa/totp/verify", {"code": first.totp.now()}).status_code == 401


def test_recovery_code_is_single_use(make_staff, new_api):
    user = make_staff()
    owner = new_api().sign_in(user)
    a, b = new_api(), new_api()
    a.login(user)
    assert a.post("auth/mfa/recovery/verify", {"code": owner.codes[0].lower()}).status_code == 200
    b.login(user)
    assert b.post("auth/mfa/recovery/verify", {"code": owner.codes[0]}).status_code == 401


def test_mfa_guessing_revokes_the_session(make_staff, new_api):
    user = make_staff()
    new_api().sign_in(user)
    thief = new_api()
    thief.login(user)
    codes = [thief.post("auth/mfa/totp/verify", {"code": "000000"}).status_code for _ in range(5)]
    assert codes[:4] == [401] * 4 and codes[4] == 429
    assert thief.get("auth/session").status_code in (401, 403)


def test_mfa_guessing_is_capped_across_sessions(make_staff, new_api):
    user = make_staff()
    new_api().sign_in(user)
    seen = set()
    for i in range(6):
        thief = new_api(ip=f"198.51.100.{i}")
        thief.login(user)
        for _ in range(4):
            seen.add(thief.post("auth/mfa/totp/verify", {"code": "000000"}).status_code)
    assert 429 in seen


def test_unknown_and_wrong_password_look_identical(api, make_staff):
    user = make_staff()
    a = api.post("auth/login", {"email": "ghost@example.test", "password": "x" * 14})
    b = api.login(user, "wrong password here")
    strip = lambda r: {k: v for k, v in r.json().items() if k != "request_id"}  # noqa: E731
    assert a.status_code == b.status_code == 401 and strip(a) == strip(b)


@pytest.mark.parametrize("state", ["non_staff", "deactivated"])
def test_ineligible_accounts_cannot_sign_in(api, make_staff, state):
    user = make_staff()
    if state == "non_staff":
        user.is_staff_member = False
    else:
        user.status = UserStatus.DEACTIVATED
    user.save()
    assert api.login(user).status_code == 401


def test_progressive_delay_then_lockout_even_with_right_password(api, make_staff):
    user = make_staff()
    for _ in range(3):
        api.login(user, "wrong password here")
    res = api.login(user)
    assert res.status_code == 429 and int(res["Retry-After"]) >= 1


def test_lockout_is_per_ip_so_victims_are_not_locked_out(make_staff, new_api):
    user = make_staff()
    attacker = new_api(ip="198.51.100.9")
    for _ in range(4):
        attacker.login(user, "wrong password here")
    assert attacker.login(user).status_code == 429
    assert new_api(ip="203.0.113.77").login(user).status_code == 200


def test_login_fails_closed_without_redis(api, make_staff, monkeypatch):
    user = make_staff()

    class Down:
        def __getattr__(self, _):
            def boom(*a, **k):
                raise redis.ConnectionError

            return boom

    monkeypatch.setattr(login_mod, "cache", Down)
    assert api.login(user).status_code == 503


# ---- session lifetime -----------------------------------------------------------------------------------
def _age(**kw):
    StaffSession.objects.update(**kw)


def test_idle_timeout(api, make_staff):
    api.sign_in(make_staff())
    _age(last_seen_at=timezone.now() - timedelta(minutes=16))
    assert api.get("integrations").status_code == 401
    assert StaffSession.objects.get().revoke_reason == "idle_timeout"


def test_absolute_timeout(api, make_staff):
    api.sign_in(make_staff())
    _age(expires_at=timezone.now())
    assert api.get("integrations").status_code == 401


def test_stolen_cookie_on_another_device_kills_the_session(make_staff, new_api):
    owner = new_api().sign_in(make_staff())
    thief = new_api(ua="Mozilla/5.0 (Windows NT 10.0) Firefox/140.0")
    thief.client.cookies[COOKIE] = owner.client.cookies[COOKIE].value
    assert thief.get("integrations").status_code == 401
    assert owner.get("integrations").status_code == 401
    assert AuthEvent.objects.filter(kind="session_hijack_suspected").exists()


def test_browser_update_keeps_the_session(api, make_staff):
    api.sign_in(make_staff())
    api.ua = UA.replace("140.0", "141.0")
    assert api.get("integrations").status_code == 200


def test_deactivation_takes_effect_immediately(admin_api):
    _, boss = admin_api()
    victim, theirs = admin_api("admin")
    assert theirs.get("integrations").status_code == 200
    assert boss.post(f"staff/{victim.pk}/status", {"active": False, "reason": "left"}).status_code == 204
    assert theirs.get("integrations").status_code == 401


# ---- csrf and origin ------------------------------------------------------------------------------------
def test_csrf_token_required(api, make_staff):
    api.sign_in(make_staff())
    assert api.post("audit/verify", **{"x-csrf-token": ""}).json()["code"] == "csrf_failed"


def test_csrf_token_from_another_session_fails(make_staff, new_api):
    a, b = new_api().sign_in(make_staff()), new_api().sign_in(make_staff())
    assert a.post("audit/verify", **{"x-csrf-token": b.csrf}).json()["code"] == "csrf_failed"


@pytest.mark.parametrize("origin", ["https://evil.example", "null", ""])
def test_foreign_or_missing_origin_refused(api, make_staff, origin):
    user = make_staff()
    api.origin = origin
    assert api.login(user).json()["code"] == "csrf_failed"


# ---- step-up --------------------------------------------------------------------------------------------
def test_step_up_gate_and_refresh(api, make_staff):
    api.sign_in(make_staff())
    _age(mfa_verified_at=timezone.now() - timedelta(minutes=6))
    res = api.post("me/recovery-codes")
    assert res.status_code == 403 and res.json()["code"] == "step_up_required"
    assert api.post("auth/mfa/recovery/verify", {"code": api.codes[0]}).status_code == 200
    assert api.post("me/recovery-codes").status_code == 200


def test_cannot_remove_the_last_factor(api, make_staff):
    api.sign_in(make_staff())
    assert api.delete("me/factors/totp").json()["code"] == "last_factor"


# ---- geo ------------------------------------------------------------------------------------------------
@pytest.mark.parametrize(("action", "status"), [("alert", 200), ("block", 403), ("off", 200)])
def test_geo_anomaly(make_staff, new_api, settings, action, status):
    from newsplatform.site_config.models import SettingsSection

    settings.ORIGIN_VERIFY_SECRET = "s3cret"
    SettingsSection.objects.create(key="security", data={"geo_anomaly_action": action})
    user = make_staff()
    owner = new_api().sign_in(user)
    KnownDevice.objects.update(country="TZ")
    geo = {"x-origin-verify": "s3cret", "cloudfront-viewer-country": "KP"}
    other = new_api()
    other.post("auth/login", {"email": user.email, "password": PASSWORD}, **geo)
    res = other.post("auth/mfa/recovery/verify", {"code": owner.codes[0]}, **geo)
    assert res.status_code == status
    assert AuthEvent.objects.filter(kind="geo_anomaly").exists() == (action != "off")
    if action == "block":
        assert StaffSession.objects.filter(revoke_reason="geo_blocked").exists()


def test_geo_header_without_the_origin_secret_is_ignored(make_staff, new_api, settings):
    settings.ORIGIN_VERIFY_SECRET = "s3cret"
    new_api().post(
        "auth/login",
        {"email": make_staff().email, "password": PASSWORD},
        **{"cloudfront-viewer-country": "KP"},
    )
    assert StaffSession.objects.get().country == ""


# ---- invitations and resets -----------------------------------------------------------------------------
def _token(url: str) -> str:
    return url.split("#")[1]


def _accept(api, token, password=PASSWORD):
    return api.post(
        "auth/invite/accept", {"token": token, "display_name": "Asha", "password": password, "locale": "sw"}
    )


def test_invite_full_flow_is_single_use(admin_api, new_api):
    _, boss = admin_api()
    res = boss.post("staff/invites", {"email": "Asha@Example.test", "grants": [{"role": "journalist"}]})
    assert res.status_code == 201 and res.json()["link"]
    token = _token(res.json()["link"])
    assert token not in str(list(StaffToken.objects.values()))
    asha = new_api()
    assert _accept(asha, token).json()["stage"] == "mfa_enroll"
    asha.enrol_totp()
    perms = asha.get("auth/session").json()["permissions"]
    assert "content.create" in perms and "staff.manage" not in perms
    assert _accept(new_api(), token).json()["code"] == "invalid_link"


@pytest.mark.parametrize("field", ["expires_at", "revoked_at", "used_at"])
def test_dead_invites(admin_api, new_api, field):
    _, boss = admin_api()
    url = boss.post("staff/invites", {"email": "a@example.test", "grants": [{"role": "journalist"}]}).json()[
        "link"
    ]
    StaffToken.objects.update(**{field: timezone.now()})
    assert _accept(new_api(), _token(url)).status_code == 404


def test_invite_dies_with_the_inviters_authority(admin_api, new_api):
    boss_user, boss = admin_api()
    admin_api()
    url = boss.post("staff/invites", {"email": "a@example.test", "grants": [{"role": "admin"}]}).json()[
        "link"
    ]
    boss_user.assignments.all().delete()
    assert _accept(new_api(), _token(url)).status_code == 403
    assert not User.objects.filter(email="a@example.test").exists()


def test_admin_cannot_invite_super_admin(admin_api):
    _, admin = admin_api("admin")
    res = admin.post("staff/invites", {"email": "x@example.test", "grants": [{"role": "super_admin"}]})
    assert res.json()["code"] == "privilege_escalation"


def test_admin_cannot_take_over_super_admin_by_reset(admin_api, make_staff):
    boss = make_staff()
    _, admin = admin_api("admin")
    for path, body in (("reset", {"reset_mfa": True}), ("status", {"active": False, "reason": "x"})):
        assert admin.post(f"staff/{boss.pk}/{path}", body).json()["code"] == "privilege_escalation"


def test_reset_revokes_sessions_and_mfa(admin_api, new_api):
    _, boss = admin_api()
    user, theirs = admin_api("journalist")
    url = boss.post(f"staff/{user.pk}/reset", {"reset_mfa": True}).json()["link"]
    assert theirs.get("me/security").status_code == 401
    new = "a wholly different passphrase"
    assert new_api().post("auth/reset/complete", {"token": _token(url), "password": new}).status_code == 204
    user.refresh_from_db()
    again = new_api()
    assert again.login(user, new).json()["stage"] == "mfa_enroll"


def test_password_rules(admin_api, new_api, monkeypatch):
    from newsplatform.staff_security import passwords

    _, boss = admin_api()
    url = boss.post("staff/invites", {"email": "a@example.test", "grants": [{"role": "journalist"}]}).json()[
        "link"
    ]
    assert _accept(new_api(), _token(url), "short").json()["code"] == "password_length"
    monkeypatch.setattr(passwords, "_breach_count", lambda p: 7)
    assert _accept(new_api(), _token(url)).json()["code"] == "password_breached"
    monkeypatch.setattr(passwords, "_breach_count", lambda p: None)
    # Breach service down: fall back to the local list, and still accept a good password.
    assert _accept(new_api(), _token(url), "q1w2e3r4t5y6").json()["code"] == "password_breached"
    assert not User.objects.filter(email="a@example.test").exists()
    assert _accept(new_api(), _token(url)).status_code == 200


def test_hibp_sends_only_five_characters(monkeypatch):
    import hashlib
    import importlib

    from newsplatform.common.http import SafeResponse
    from newsplatform.staff_security import passwords as live

    mod = importlib.reload(live)
    digest = hashlib.sha1(b"hunter2hunter2").hexdigest().upper()
    sent = []

    def fake(method, url, **kw):
        sent.append(url)
        return SafeResponse(200, {}, f"{'0' * 35}:0\r\n{digest[5:]}:42".encode())

    monkeypatch.setattr(mod, "fetch", fake)
    assert mod._breach_count("hunter2hunter2") == 42
    assert sent == [f"https://api.pwnedpasswords.com/range/{digest[:5]}"]


def test_password_is_argon2id(make_staff):
    assert make_staff().password.startswith("argon2$argon2id$")


def test_changing_password_ends_other_sessions(make_staff, new_api):
    user = make_staff()
    one = new_api().sign_in(user)
    two = new_api()
    two.login(user)
    two.post("auth/mfa/recovery/verify", {"code": one.codes[0]})
    res = one.post("me/password", {"current": PASSWORD, "new": "another long passphrase"})
    assert res.status_code == 204
    assert two.get("me/security").status_code == 401 and one.get("me/security").status_code == 200


def test_other_users_sessions_are_unreachable(admin_api):
    _, a = admin_api()
    b_user, b = admin_api()
    target = StaffSession.objects.get(user=b_user)
    assert a.delete(f"me/sessions/{target.pk}").status_code == 404
    assert b.get("me/security").status_code == 200


def test_no_secrets_stored_in_clear(api, make_staff):
    from newsplatform.staff_security.models import RecoveryCode, TotpDevice

    user = make_staff()
    api.sign_in(user)
    assert api.totp.secret not in str(TotpDevice.objects.values())
    assert api.client.cookies[COOKIE].value not in str(list(StaffSession.objects.values()))
    assert api.codes[0].replace("-", "") not in str(list(RecoveryCode.objects.values()))


def test_bootstrap_stops_after_two_super_admins(make_staff):
    from django.core.management import CommandError, call_command

    make_staff()
    make_staff()
    with pytest.raises(CommandError):
        call_command("bootstrap_super_admin", "third@example.test")
