"""Readers sign in, and engage (ADR-0050)."""

import time
from datetime import timedelta
from typing import Any

import httpx
import pytest
import respx
from django.test import Client
from django.utils import timezone
from freezegun import freeze_time
from joserfc import jwt
from joserfc.jwk import ECKey, KeySet, RSAKey

from newsplatform.accounts import phones, signin, tokens
from newsplatform.accounts.models import Identity, OtpChallenge, RefreshToken, User, UserStatus
from newsplatform.content import tasks
from newsplatform.engagement import counters
from newsplatform.engagement.models import Comment, Like
from newsplatform.integrations.providers import apple_signin, beem, google_signin
from newsplatform.site_config.models import SettingsSection
from tests import factories as f

pytestmark = pytest.mark.django_db
API = "/api/v1/"


@pytest.fixture(autouse=True)
def _public(settings, monkeypatch):
    settings.ROOT_URLCONF = "config.urls_public"
    settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "IpAllowlist" not in m]
    settings.LOCAL_SMS = True
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: None)


def post(path: str, data: Any = None, token: str = "", **kw: Any):
    headers = {"HTTP_AUTHORIZATION": f"Bearer {token}"} if token else {}
    return Client().post(API + path, data or {}, content_type="application/json", **headers, **kw)


def call(method: str, path: str, token: str = "", data: Any = None):
    headers = {"HTTP_AUTHORIZATION": f"Bearer {token}"} if token else {}
    return getattr(Client(), method)(API + path, data, content_type="application/json", **headers)


def forget_limits() -> None:
    from newsplatform.common.redis import cache

    for key in cache().scan_iter("rl:*"):
        cache().delete(key)


def sign_in(phone: str = "0712345678") -> dict[str, Any]:
    forget_limits()  # each sign-in here stands for one on another day
    sent = post("auth/code", {"phone": phone}).json()
    done = post("auth/code/verify", {"challenge": sent["challenge"], "code": sent["local_code"]})
    assert done.status_code == 200, done.content
    return done.json()


def rules(**data: Any) -> None:
    SettingsSection.objects.update_or_create(key="sign_in", defaults={"data": data, "version": 2})


# ---- phone numbers ----
@pytest.mark.parametrize(
    ("raw", "e164"),
    [
        ("0712 345 678", "+255712345678"),
        ("+255 712-345-678", "+255712345678"),
        ("255712345678", "+255712345678"),
        ("00255712345678", "+255712345678"),
        ("0612345678", "+255612345678"),
        ("+254712345678", "+254712345678"),
        ("0812345678", None),  # not a Tanzanian mobile
        ("12345", None),
        ("", None),
    ],
)
def test_numbers_become_e164(raw, e164):
    assert phones.normalise(raw) == e164


# ---- SMS codes ----
def test_a_phone_and_its_code_make_an_account_and_sign_in_again_to_it():
    first = sign_in()
    assert first["created"] is True
    assert first["user"]["phone"] == "+255712345678" and first["user"]["onboarding"] is True
    assert first["user"]["username"].startswith("msomaji")
    again = sign_in("+255 712 345 678")
    assert again["created"] is False and again["user"]["id"] == first["user"]["id"]
    assert User.objects.count() == 1 and Identity.objects.get().provider == "phone"


def test_only_a_hash_of_the_code_is_kept_and_it_is_used_once():
    sent = post("auth/code", {"phone": "0712345678"}).json()
    row = OtpChallenge.objects.get()
    assert sent["local_code"] not in row.code_hash and len(row.code_hash) == 64
    assert (
        post("auth/code/verify", {"challenge": sent["challenge"], "code": sent["local_code"]}).status_code
        == 200
    )
    reused = post("auth/code/verify", {"challenge": sent["challenge"], "code": sent["local_code"]})
    assert reused.json()["code"] == "code_expired"


def test_wrong_codes_count_and_lock_the_code():
    sent = post("auth/code", {"phone": "0712345678"}).json()
    wrong = "000000" if sent["local_code"] != "000000" else "111111"
    for left in (4, 3, 2, 1, 0):
        res = post("auth/code/verify", {"challenge": sent["challenge"], "code": wrong})
        assert res.json()["code"] == "code_wrong" and res.json()["attempts_left"] == left
    locked = post("auth/code/verify", {"challenge": sent["challenge"], "code": sent["local_code"]})
    assert locked.json()["code"] == "code_locked"


def test_a_code_expires():
    sent = post("auth/code", {"phone": "0712345678"}).json()
    with freeze_time(timezone.now() + timedelta(minutes=6)):
        res = post("auth/code/verify", {"challenge": sent["challenge"], "code": sent["local_code"]})
    assert res.json()["code"] == "code_expired"


def test_codes_go_only_to_allowed_countries_and_wait_between_sends():
    assert post("auth/code", {"phone": "+254712345678"}).json()["code"] == "country_not_allowed"
    assert post("auth/code", {"phone": "07123"}).json()["code"] == "invalid_phone"
    assert post("auth/code", {"phone": "0712345678"}).status_code == 201
    again = post("auth/code", {"phone": "0712345678"})
    assert again.status_code == 429 and int(again.headers["Retry-After"]) > 30
    rules(countries=["255", "254"])
    assert post("auth/code", {"phone": "+254712345678"}).status_code == 201


def test_one_network_cannot_pump_codes_to_many_numbers():
    rules(per_ip_hourly=5, resend_seconds=30)
    codes = [post("auth/code", {"phone": f"07123456{i:02d}"}).status_code for i in range(7)]
    assert codes[:5] == [201] * 5 and codes[5:] == [429, 429]


def test_the_hourly_sms_budget_stops_everyone():
    rules(sms_hourly_budget=10, per_ip_hourly=500)
    codes = [
        post("auth/code", {"phone": f"0712{i:06d}"}, REMOTE_ADDR=f"198.51.100.{i}").status_code
        for i in range(12)
    ]
    assert codes.count(201) == 10 and codes[-1] == 429


def test_without_beem_and_outside_local_there_is_no_phone_sign_in(settings):
    settings.LOCAL_SMS = False
    assert Client().get(API + "auth/methods").json()["phone"] is False
    assert post("auth/code", {"phone": "0712345678"}).json()["code"] == "sms_not_configured"


@respx.mock
def test_with_beem_the_code_goes_by_sms_and_is_not_in_the_answer(settings, monkeypatch):
    settings.LOCAL_SMS = False
    config = beem.BeemConfig(api_key="key-12345678", secret_key="secret", sender_id="MFANO")
    monkeypatch.setattr(signin, "beem", lambda: config)
    route = respx.post(beem.SEND).mock(
        return_value=httpx.Response(200, json={"successful": True, "request_id": 67, "code": 100, "valid": 1})
    )
    res = post("auth/code", {"phone": "0712345678"})
    assert res.status_code == 201 and "local_code" not in res.json()
    sent = route.calls.last.request
    assert sent.headers["Authorization"].startswith("Basic ")
    body = __import__("json").loads(sent.content)
    assert body["source_addr"] == "MFANO" and body["recipients"][0]["dest_addr"] == "255712345678"
    assert "msimbo wako wa kuingia" in body["message"]
    assert OtpChallenge.objects.get().provider_ref == "67"


@respx.mock
def test_a_beem_refusal_is_told_and_no_challenge_is_kept(settings, monkeypatch):
    settings.LOCAL_SMS = False
    monkeypatch.setattr(
        signin, "beem", lambda: beem.BeemConfig(api_key="key-12345678", secret_key="s", sender_id="MFANO")
    )
    respx.post(beem.SEND).mock(
        return_value=httpx.Response(400, json={"code": 111, "message": "Invalid Sender ID"})
    )
    assert post("auth/code", {"phone": "0712345678"}).json()["code"] == "sms_failed"
    assert OtpChallenge.objects.count() == 0


@respx.mock
def test_the_beem_test_button_reads_the_balance_checks_the_sender_and_sends():
    from newsplatform.integrations.base import Test

    config = beem.BeemConfig(api_key="key-12345678", secret_key="s", sender_id="MFANO")
    respx.get(beem.BALANCE).mock(return_value=httpx.Response(200, json={"data": {"credit_balance": 120.5}}))
    respx.get(beem.SENDERS).mock(
        return_value=httpx.Response(200, json={"data": [{"senderid": "MFANO", "status": "active"}]})
    )
    respx.post(beem.SEND).mock(
        return_value=httpx.Response(
            200, json={"successful": True, "request_id": "9", "code": 100, "valid": 1}
        )
    )
    t = Test("beem_sms", lambda steps: None)
    beem.BeemProvider().test(config, t, {"phone": "0712345678"})
    assert [(s.key, s.status) for s in t.steps] == [
        ("balance", "passed"),
        ("sender", "passed"),
        ("send", "passed"),
    ]

    respx.get(beem.BALANCE).mock(return_value=httpx.Response(401, json={"code": 120, "message": "Invalid"}))
    t = Test("beem_sms", lambda steps: None)
    beem.BeemProvider().test(config, t, {"phone": "0712345678"})
    assert t.steps[0].status == "failed" and "key or secret" in t.steps[0].remediation
    assert [s.status for s in t.steps[1:]] == ["skipped", "skipped"]


# ---- tokens ----
def test_refresh_tokens_rotate_and_a_reused_one_ends_the_whole_family():
    first = sign_in()
    second = post("auth/refresh", {"refresh": first["refresh"]})
    assert second.status_code == 200
    third = post("auth/refresh", {"refresh": second.json()["refresh"]})
    assert third.status_code == 200
    # The first token, presented again: stolen. Everything from that sign-in ends.
    replay = post("auth/refresh", {"refresh": first["refresh"]})
    assert replay.status_code == 401 and replay.json()["code"] == "token_reused"
    assert post("auth/refresh", {"refresh": third.json()["refresh"]}).status_code == 401
    assert RefreshToken.objects.filter(revoked_at__isnull=True).count() == 0


def test_an_access_token_works_until_signing_out_and_never_when_forged():
    done = sign_in()
    assert call("get", "me", done["access"]).status_code == 200
    forged = done["access"][:-4] + ("AAAA" if not done["access"].endswith("AAAA") else "BBBB")
    assert call("get", "me", forged).status_code == 401
    assert call("get", "me").status_code == 401
    post("auth/sign-out", {"refresh": done["refresh"]})
    from django.core.cache import cache

    cache.clear()
    assert call("get", "me", done["access"]).status_code == 401


def test_an_access_token_expires_after_ten_minutes():
    done = sign_in()
    with freeze_time(timezone.now() + timedelta(seconds=tokens.ACCESS_SECONDS + 5)):
        assert call("get", "me", done["access"]).status_code == 401


def test_readers_answers_are_never_cached():
    done = sign_in()
    res = call("get", "me", done["access"])
    assert res.headers["Cache-Control"] == "no-store"
    assert post("auth/code", {"phone": "0712345679"}).headers["Cache-Control"] == "no-store"


# ---- the account ----
def test_a_new_reader_says_a_name_and_accepts_the_terms_once():
    done = sign_in()
    res = call("patch", "me", done["access"], {"display_name": "  Asha   Juma ", "accept_terms": True})
    assert res.json()["display_name"] == "Asha Juma" and res.json()["onboarding"] is False
    assert call("patch", "me", done["access"], {"display_name": "A"}).json()["code"] == "validation_error"
    rules(terms_version="2027-01")
    assert call("get", "me", done["access"]).json()["onboarding"] is True  # new terms, asked again


def test_usernames_are_unique_whatever_the_case():
    a, b = sign_in("0712345678"), sign_in("0712345679")
    assert call("patch", "me", a["access"], {"username": "Asha_J"}).json()["username"] == "asha_j"
    assert call("patch", "me", b["access"], {"username": "ASHA_J"}).json()["code"] == "username_taken"
    assert call("patch", "me", b["access"], {"username": "a b"}).json()["code"] == "validation_error"


def test_deleting_signs_out_everywhere_and_signing_in_within_the_grace_keeps_the_account():
    done = sign_in()
    assert call("delete", "me", done["access"], {"confirm": "delete"}).status_code == 202
    user = User.objects.get()
    assert user.status == UserStatus.DEACTIVATED and user.deletion_requested_at
    assert post("auth/refresh", {"refresh": done["refresh"]}).status_code == 401
    sign_in()
    user.refresh_from_db()
    assert user.status == UserStatus.ACTIVE and user.deletion_requested_at is None
    call("delete", "me", sign_in()["access"], {"confirm": "delete"})
    with freeze_time(timezone.now() + timedelta(days=31)):
        assert signin.erase_due() == 1
    assert User.objects.count() == 0


def test_a_reader_can_take_their_data():
    done = sign_in()
    res = call("get", "me/export", done["access"])
    assert res.status_code == 200 and "attachment" in res.headers["Content-Disposition"]
    assert res.json()["account"]["phone"] == "+255712345678"


# ---- Google and Apple ----
def _token(key: Any, alg: str, **claims: Any) -> str:
    now = int(time.time())
    return jwt.encode({"alg": alg, "kid": key.kid}, {"iat": now, "exp": now + 600, **claims}, key)


@pytest.fixture
def google(monkeypatch):
    key = RSAKey.generate_key(2048, parameters={"kid": "g1"})
    config = google_signin.GoogleConfig(
        web_client_id="123-abc.apps.googleusercontent.com",
        web_client_secret="secret",
        android_client_id="456-def.apps.googleusercontent.com",
    )
    monkeypatch.setattr(signin, "google", lambda: config)
    with respx.mock:
        respx.get(google_signin.DISCOVERY).mock(
            return_value=httpx.Response(
                200,
                json={
                    "issuer": "https://accounts.google.com",
                    "jwks_uri": "https://www.googleapis.com/oauth2/v3/certs",
                    "token_endpoint": "https://oauth2.googleapis.com/token",
                },
            )
        )
        respx.get("https://www.googleapis.com/oauth2/v3/certs").mock(
            return_value=httpx.Response(200, json=KeySet([key]).as_dict(private=False))
        )
        yield key, config


def test_google_makes_an_account_from_a_verified_token(google):
    key, _ = google
    claims = {
        "iss": "https://accounts.google.com",
        "sub": "g-1",
        "email": "Asha@Gmail.com",
        "name": "Asha Juma",
    }
    token = _token(key, "RS256", aud="456-def.apps.googleusercontent.com", email_verified=True, **claims)
    res = post("auth/google", {"id_token": token})
    assert res.status_code == 200, res.content
    assert (
        res.json()["user"]["email"] == "asha@gmail.com" and res.json()["user"]["display_name"] == "Asha Juma"
    )


@pytest.mark.parametrize(
    "bad",
    [
        {"aud": "someone-else.apps.googleusercontent.com"},
        {"iss": "https://evil.example"},
        {"exp": int(time.time()) - 3600},
    ],
)
def test_google_refuses_tokens_for_others_from_others_or_old(google, bad):
    key, _ = google
    claims = {"iss": "https://accounts.google.com", "sub": "g-1", "aud": "123-abc.apps.googleusercontent.com"}
    res = post("auth/google", {"id_token": _token(key, "RS256", **{**claims, **bad})})
    assert res.status_code == 400 and res.json()["code"] == "invalid_identity_token"


def test_google_refuses_a_token_signed_by_anyone_else(google):
    other = RSAKey.generate_key(2048, parameters={"kid": "g1"})
    token = _token(
        other, "RS256", iss="accounts.google.com", sub="g", aud="123-abc.apps.googleusercontent.com"
    )
    assert post("auth/google", {"id_token": token}).json()["code"] == "invalid_identity_token"


def test_google_on_the_website_exchanges_its_code(google):
    key, _ = google
    token = _token(
        key, "RS256", iss="accounts.google.com", sub="g-2", aud="123-abc.apps.googleusercontent.com"
    )
    route = respx.post("https://oauth2.googleapis.com/token").mock(
        return_value=httpx.Response(200, json={"id_token": token})
    )
    res = post(
        "auth/google",
        {"code": "c", "redirect_uri": "https://site/api/auth/google/callback", "code_verifier": "v"},
    )
    assert res.status_code == 200, res.content
    assert b"code_verifier=v" in route.calls.last.request.content
    assert b"client_secret=secret" in route.calls.last.request.content


def test_an_unverified_google_email_is_not_linked_to_an_account_with_that_email(google):
    key, _ = google
    User.objects.create_user(email="asha@gmail.com", display_name="Asha", username="asha")
    token = _token(
        key,
        "RS256",
        iss="accounts.google.com",
        sub="g-3",
        aud="123-abc.apps.googleusercontent.com",
        email="asha@gmail.com",
        email_verified=False,
    )
    res = post("auth/google", {"id_token": token})
    assert res.json()["created"] is True and User.objects.count() == 2


@pytest.fixture
def apple(monkeypatch):
    signer = ECKey.generate_key("P-256", parameters={"kid": "a1"})
    p8 = ECKey.generate_key("P-256").as_pem(private=True).decode()
    config = apple_signin.AppleConfig(
        team_id="ABCDE12345",
        key_id="KEY1234567",
        services_id="africa.mfano.web",
        bundle_id="africa.mfano.app",
        private_key=p8.replace("\n", " "),  # as a one-line field leaves it
    )
    monkeypatch.setattr(signin, "apple", lambda: config)
    with respx.mock:
        respx.get(apple_signin.KEYS).mock(
            return_value=httpx.Response(200, json=KeySet([signer]).as_dict(private=False))
        )
        yield signer, config


def test_apple_from_the_app_with_its_nonce_and_the_name_given_once(apple):
    signer, _ = apple
    token = _token(
        signer,
        "ES256",
        iss=apple_signin.ISSUER,
        sub="a-1",
        aud="africa.mfano.app",
        nonce="n1",
        email="x@privaterelay.appleid.com",
        email_verified="true",
        is_private_email="true",
    )
    res = post("auth/apple", {"id_token": token, "nonce": "n1", "name": "Juma Ali"})
    assert res.status_code == 200, res.content
    assert res.json()["user"]["display_name"] == "Juma Ali"
    assert (
        post("auth/apple", {"id_token": token, "nonce": "other"}).json()["code"] == "invalid_identity_token"
    )


def test_apple_on_the_website_exchanges_its_code_with_a_signed_secret_and_keeps_the_token_to_revoke(apple):
    signer, config = apple
    token = _token(signer, "ES256", iss=apple_signin.ISSUER, sub="a-2", aud="africa.mfano.web")
    route = respx.post(apple_signin.TOKEN).mock(
        return_value=httpx.Response(200, json={"id_token": token, "refresh_token": "r-apple"})
    )
    assert (
        post("auth/apple", {"code": "c", "redirect_uri": "https://site/api/auth/apple/callback"}).status_code
        == 200
    )
    body = dict(x.split("=", 1) for x in route.calls.last.request.content.decode().split("&"))
    secret = jwt.decode(body["client_secret"], ECKey.import_key(config.private_key.get_secret_value()))
    assert (
        secret.header == {"alg": "ES256", "kid": "KEY1234567", "typ": "JWT"}
        or secret.header["kid"] == "KEY1234567"
    )
    assert secret.claims["iss"] == "ABCDE12345" and secret.claims["sub"] == "africa.mfano.web"
    assert secret.claims["aud"] == "https://appleid.apple.com"
    assert Identity.objects.get(provider="apple").revoke_token == "r-apple"


def test_apple_test_button_reads_invalid_grant_as_accepted(apple):
    from newsplatform.integrations.base import Test

    _, config = apple
    respx.post(apple_signin.TOKEN).mock(return_value=httpx.Response(400, json={"error": "invalid_grant"}))
    t = Test("apple_signin", lambda s: None)
    apple_signin.AppleProvider().test(config, t, {})
    assert [s.status for s in t.steps] == ["passed", "passed", "passed"]
    respx.post(apple_signin.TOKEN).mock(return_value=httpx.Response(400, json={"error": "invalid_client"}))
    t = Test("apple_signin", lambda s: None)
    apple_signin.AppleProvider().test(config, t, {})
    assert t.steps[1].status == "failed" and "Team ID" in t.steps[1].remediation


def test_a_pasted_key_is_made_a_proper_pem_whatever_its_line_breaks():
    pem = ECKey.generate_key("P-256").as_pem(private=True).decode()
    for pasted in (pem, pem.replace("\n", " "), pem.replace("\n", "\\n"), pem.replace("\n", "")):
        assert apple_signin.pem(pasted) == apple_signin.pem(pem)
    with pytest.raises(ValueError):
        apple_signin.pem("not a key")


def test_methods_show_only_what_is_switched_on_and_configured(google):
    m = Client().get(API + "auth/methods").json()
    assert m["phone"] and m["google"] and m["google_client_id"] == "123-abc.apps.googleusercontent.com"
    assert m["apple"] is False and m["countries"] == ["255"]
    rules(google=False)
    assert Client().get(API + "auth/methods").json()["google"] is False


# ---- engagement ----
@pytest.fixture
def story(make_staff):
    editor = make_staff("editor_in_chief")
    from newsplatform.content import services

    cat = f.category("habari")
    row = services.create(actor=editor, type="article", category=cat, locale="sw", headline="Habari ya leo")
    texts = {"sw": {"headline": "Habari ya leo", "standfirst": "Utangulizi", "body": f.body()}}
    row = services.save(actor=editor, post_id=row.pk, version=row.version, data={"texts": texts})
    services.release_lock(actor=editor, post_id=row.pk)
    return f.go(editor, row, "publish")


def test_likes_are_idempotent_and_counted_once(story):
    a, b = sign_in("0712345678")["access"], sign_in("0712345679")["access"]
    path = f"engagement/posts/{story.pk}/like"
    assert call("put", path, a).json()["likes"] == 1
    assert call("put", path, a).json()["likes"] == 1  # a double tap
    assert call("put", path, b).json()["likes"] == 2
    assert call("delete", path, a).json()["likes"] == 1
    assert Like.objects.count() == 1
    state = Client().get(API + f"engagement/state?posts={story.pk}", HTTP_AUTHORIZATION=f"Bearer {b}").json()
    assert state[str(story.pk)] == {
        "likes": 1,
        "comments": 0,
        "bookmarks": 0,
        "views": 0,
        "readers": 0,
        "liked": True,
        "bookmarked": False,
        "likes_on": True,
        "comments_on": True,
    }


def test_cards_show_counts_by_default_and_never_one_a_story_does_not_allow(story, make_staff):
    from django.core.cache import cache

    def state(*ids: str) -> dict[str, Any]:
        return Client().get(API + f"engagement/state?posts={','.join(ids)}").json()

    assert Client().get(API + "site-config").json()["engagement"] == {"card_counts": True}
    assert Client().get(API + "app-config").json()["flags"]["card_counts"] is True
    # Likes off for the whole section, comments closed on this story: the card is told both.
    story.category.engagement = {"likes": False}
    story.category.save()
    story.engagement = {"comments": "closed"}
    story.save()
    cache.clear()
    editor = make_staff("editor_in_chief")
    other = f.go(editor, f.post(editor, f.category("michezo"), "Mpira"), "publish")
    got = state(str(story.pk), str(other.pk), "00000000-0000-0000-0000-000000000000")
    assert (got[str(story.pk)]["likes_on"], got[str(story.pk)]["comments_on"]) == (False, False)
    assert (got[str(other.pk)]["likes_on"], got[str(other.pk)]["comments_on"]) == (True, True)
    assert got["00000000-0000-0000-0000-000000000000"]["likes_on"] is False  # not a published story
    # The switch in Settings → Engagement turns the counts off on every card.
    SettingsSection.objects.update_or_create(
        key="engagement", defaults={"data": {"card_counts": False}, "version": 3}
    )
    cache.clear()
    assert Client().get(API + "site-config").json()["engagement"] == {"card_counts": False}
    assert Client().get(API + "app-config").json()["flags"]["card_counts"] is False


def test_counts_survive_a_lost_cache(story):
    a = sign_in()["access"]
    call("put", f"engagement/posts/{story.pk}/like", a)
    counters.forget(story.pk)
    assert counters.get([str(story.pk)])[str(story.pk)]["likes"] == 1


def test_guests_are_asked_to_sign_in(story):
    res = call("put", f"engagement/posts/{story.pk}/like")
    assert res.status_code == 401 and res.json()["code"] == "unauthenticated"


def test_a_kill_switch_stops_likes_at_once_whatever_the_client_shows(story):
    a = sign_in()["access"]
    SettingsSection.objects.update_or_create(
        key="engagement", defaults={"data": {"kill": {"likes": True}}, "version": 2}
    )
    from django.core.cache import cache

    cache.clear()
    res = call("put", f"engagement/posts/{story.pk}/like", a)
    assert res.status_code == 403 and res.json()["code"] == "engagement_disabled"


def test_comments_thread_one_level_deep_and_count(story):
    a, b = sign_in("0712345678")["access"], sign_in("0712345679")["access"]
    path = f"engagement/posts/{story.pk}/comments"
    first = call("post", path, a, {"body": "Habari nzuri sana!"}).json()
    reply = call("post", path, b, {"body": "Kweli kabisa", "parent": first["id"]}).json()
    forget_limits()  # ten seconds on, as slow mode asks
    deeper = call("post", path, a, {"body": "Asante", "parent": reply["id"]}).json()
    assert deeper["parent"] == first["id"]  # a reply to a reply belongs to the first comment
    page = Client().get(API + path).json()
    assert [c["body"] for c in page["results"]] == ["Habari nzuri sana!"] and page["count"] == 3
    assert page["results"][0]["reply_count"] == 2
    replies = Client().get(API + path + f"?parent={first['id']}").json()["results"]
    assert [c["body"] for c in replies] == ["Kweli kabisa", "Asante"]


def test_slow_mode_and_limits_on_comments(story):
    a = sign_in()["access"]
    path = f"engagement/posts/{story.pk}/comments"
    assert call("post", path, a, {"body": "Ya kwanza"}).status_code == 201
    assert call("post", path, a, {"body": "Ya pili"}).status_code == 429
    assert call("post", path, a, {"body": " "}).json()["code"] in {"validation_error", "rate_limited"}


def test_closed_and_premoderated_comments(story, make_staff):
    a = sign_in()["access"]
    path = f"engagement/posts/{story.pk}/comments"
    story.engagement = {"comments": "closed"}
    story.save()
    assert call("post", path, a, {"body": "Hello"}).json()["code"] == "engagement_disabled"
    story.engagement = {"comments": "premoderated"}
    story.version += 1
    story.save()
    held = call("post", path, a, {"body": "Inasubiri"}).json()
    assert held["held"] is True
    assert Client().get(API + path).json()["results"] == []  # others do not see it yet
    mine = Client().get(API + path, HTTP_AUTHORIZATION=f"Bearer {a}").json()["results"]
    assert [c["body"] for c in mine] == ["Inasubiri"]


def test_a_reader_deletes_their_own_comment_only(story):
    a, b = sign_in("0712345678")["access"], sign_in("0712345679")["access"]
    c = call("post", f"engagement/posts/{story.pk}/comments", a, {"body": "Yangu"}).json()
    assert call("delete", f"engagement/comments/{c['id']}", b).status_code == 404
    assert call("delete", f"engagement/comments/{c['id']}", a).status_code == 204
    assert Comment.objects.get().status == "removed"
    assert counters.get([str(story.pk)])[str(story.pk)]["comments"] == 0


def test_comment_likes_and_saved_list(story):
    a = sign_in()["access"]
    c = call("post", f"engagement/posts/{story.pk}/comments", a, {"body": "Nzuri"}).json()
    assert call("put", f"engagement/comments/{c['id']}/like", a).json()["like_count"] == 1
    assert call("put", f"engagement/comments/{c['id']}/like", a).json()["like_count"] == 1
    call("put", f"engagement/posts/{story.pk}/bookmark", a)
    saved = call("get", "me/saved", a).json()["results"]
    assert [s["id"] for s in saved] == [str(story.pk)]


def test_follows(story):
    a = sign_in()["access"]
    cat = story.category_id
    assert call("put", f"engagement/follows/category/{cat}", a).json()["following"] is True
    assert call("get", "me/follows", a).json()["results"] == [{"kind": "category", "target": str(cat)}]
    assert call("delete", f"engagement/follows/category/{cat}", a).json()["following"] is False


def test_the_websites_server_tells_the_readers_address_signed(monkeypatch):
    import hashlib
    import hmac

    from newsplatform.integrations import services
    from newsplatform.integrations.providers.web import WebConfig

    secret = "s" * 40
    config = WebConfig.model_construct(secret=__import__("pydantic").SecretStr(secret))
    monkeypatch.setattr(services, "get_active", lambda key, model: config if key == "web" else None)
    rules(per_ip_hourly=5, resend_seconds=30)

    def sign(ip: str) -> dict[str, str]:
        mac = hmac.new(secret.encode(), f"reader-ip:{ip}".encode(), hashlib.sha256).hexdigest()
        return {"HTTP_X_READER_IP": ip, "HTTP_X_READER_IP_MAC": mac}

    # Six readers behind the website, each from their own network: none is limited by the others.
    for i in range(6):
        assert post("auth/code", {"phone": f"07123456{i:02d}"}, **sign(f"198.51.100.{i}")).status_code == 201
    # A forged signature is ignored: these all count against the website's own address.
    forged = {"HTTP_X_READER_IP": "203.0.113.9", "HTTP_X_READER_IP_MAC": "0" * 64}
    codes = [post("auth/code", {"phone": f"07223456{i:02d}"}, **forged).status_code for i in range(6)]
    assert codes.count(429) >= 1


# ---- views and readers ----
def test_views_count_every_opening_but_one_device_once_in_half_an_hour(story):
    path = f"engagement/posts/{story.pk}/opened"
    first = post(path, {"device": "browser-aaaaaaaaaaaa"}).json()
    again = post(path, {"device": "browser-aaaaaaaaaaaa"}).json()
    other = post(path, {"device": "browser-bbbbbbbbbbbb"}).json()
    assert (first["views"], again["views"], other["views"]) == (1, 1, 2)
    assert other["readers"] == 2
    post(path, {"device": "not valid"})  # nobody to count
    assert Client().get(API + f"engagement/state?posts={story.pk}").json()[str(story.pk)]["views"] == 2


def test_views_survive_a_lost_cache_once_saved(story):
    from newsplatform.common.redis import cache
    from newsplatform.engagement import views

    for d in "abc":
        post(f"engagement/posts/{story.pk}/opened", {"device": f"browser-{d * 12}"})
    assert views.persist() == 1
    cache().flushdb()
    state = Client().get(API + f"engagement/state?posts={story.pk}").json()[str(story.pk)]
    assert state["views"] == 3 and state["readers"] == 3


def test_reconcile_keeps_the_views(story):
    post(f"engagement/posts/{story.pk}/opened", {"device": "browser-aaaaaaaaaaaa"})
    counters.reconcile([str(story.pk)])
    assert counters.get([str(story.pk)])[str(story.pk)]["views"] == 1


def test_who_read_a_story_lists_signed_in_readers_who_did_not_hide(story):
    a, b = sign_in("0712345678"), sign_in("0712345679")
    call("patch", "me", a["access"], {"display_name": "Asha Juma"})
    call("patch", "me", b["access"], {"display_name": "Baraka", "hide_from_readers": True})
    for token in (a["access"], b["access"]):
        call("post", f"engagement/posts/{story.pk}/opened", token, {})
    post(f"engagement/posts/{story.pk}/opened", {"device": "browser-cccccccccccc"})
    seen = Client().get(API + f"engagement/posts/{story.pk}/readers").json()
    assert [r["name"] for r in seen["results"]] == ["Asha Juma"]
    assert seen["readers"] == 3 and seen["guests"] == 1


def test_a_reader_writes_a_bio_and_an_email_to_be_reached_at(google):
    a = sign_in()["access"]
    res = call(
        "patch", "me", a, {"bio": "  Napenda  habari za michezo. ", "contact_email": "Asha@Example.com"}
    )
    assert res.status_code == 200, res.content
    assert (res.json()["bio"], res.json()["contact_email"]) == (
        "Napenda habari za michezo.",
        "asha@example.com",
    )
    assert call("patch", "me", a, {"bio": "x" * 161}).json()["code"] == "validation_error"
    assert call("patch", "me", a, {"contact_email": "si barua"}).json()["code"] == "validation_error"
    # Typed, not verified: whoever owns that address and signs in with Google gets an account of their own.
    key, _ = google
    claims = {"iss": "https://accounts.google.com", "sub": "g-9", "email": "asha@example.com", "name": "Asha"}
    token = _token(key, "RS256", aud="456-def.apps.googleusercontent.com", email_verified=True, **claims)
    theirs = post("auth/google", {"id_token": token}).json()["user"]
    assert theirs["id"] != call("get", "me", a).json()["id"]
