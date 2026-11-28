"""Paid reading (ADR-0052): a story for subscribers shows everyone only its opening, its whole text only to a reader
with paid time left; a payment adds time once, whatever Snippe repeats; and only Snippe's signature is believed."""

import hashlib
import hmac
import json
import time
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import pytest
from django.test import Client
from django.utils import timezone

from newsplatform.accounts import tokens
from newsplatform.accounts.models import User
from newsplatform.content import tasks
from newsplatform.content.models import Publication
from newsplatform.integrations.providers import snippe
from newsplatform.subscriptions import services
from newsplatform.subscriptions.models import Payment, Plan, Subscription
from tests import factories as f

pytestmark = pytest.mark.django_db
API = "/api/v1/"
SECRET = "whsec_test_signing_key_0123456789"


@pytest.fixture(autouse=True)
def _public(settings, monkeypatch):
    settings.ROOT_URLCONF = "config.urls_public"
    settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "IpAllowlist" not in m]
    settings.LOCAL_PAYMENTS = True
    monkeypatch.setattr(tasks.announce, "delay", lambda tags, pages: None)


@pytest.fixture
def editor(make_staff):
    return make_staff("editor_in_chief")


def paragraphs(n: int) -> dict[str, Any]:
    blocks = [
        {"type": "paragraph", "id": f"block-{i}", "content": [{"type": "text", "text": f"Aya {i}."}]}
        for i in range(n)
    ]
    return {"version": 1, "blocks": blocks}


def story(editor: User, premium: bool, headline: str = "Habari ya wanachama") -> Publication:
    from newsplatform.taxonomy.models import Category

    cat = f.category(f"biashara-{int(premium)}-{Category.objects.count()}")
    texts = {"sw": {"headline": headline, "standfirst": "Utangulizi", "body": paragraphs(6)}}
    row = f.go(editor, f.post(editor, cat, headline, texts=texts, requires_subscription=premium), "publish")
    return Publication.objects.get(post=row, locale="sw")


def reader(phone: str = "+255712000001") -> tuple[User, str]:
    user = User.objects.create_user(phone=phone, display_name="Asha Juma")
    return user, tokens.issue(user).access


def call(method: str, path: str, token: str = "", data: Any = None):
    headers = {"HTTP_AUTHORIZATION": f"Bearer {token}"} if token else {}
    return getattr(Client(), method)(API + path, data, content_type="application/json", **headers)


def plan(interval: str = "month") -> Plan:
    return Plan.objects.filter(interval=interval, highlighted=True).first() or Plan.objects.create(
        code=f"t-{interval}", interval=interval, price=5000, name_sw="Kamili", name_en="Standard"
    )


def pay(token: str, p: Plan, method: str = "mobile") -> dict[str, Any]:
    r = call(
        "post", "subscriptions/checkout", token, {"plan": str(p.pk), "method": method, "phone": "0712000001"}
    )
    assert r.status_code == 201, r.content
    return r.json()


def test_everyone_sees_the_card_and_only_the_opening_of_a_story_for_subscribers(editor):
    locked, free = story(editor, True), story(editor, False, "Habari ya wote")
    assert locked.card["premium"] is True and free.card["premium"] is False
    body = Client().get(API + f"content/articles/{locked.slug}?locale=sw").json()
    assert body["locked"] is True and body["premium"] is True
    assert [b["id"] for b in body["body"]["blocks"]] == [
        "block-0",
        "block-1",
        "block-2",
    ]  # three paragraphs, by default
    whole = Client().get(API + f"content/articles/{free.slug}?locale=sw").json()
    assert whole["locked"] is False and len(whole["body"]["blocks"]) == 6


def test_the_whole_story_is_for_a_reader_with_paid_time_left_only(editor):
    pub = story(editor, True)
    path = f"subscriptions/posts/{pub.post_id}?locale=sw"
    assert call("get", path).status_code == 401
    user, token = reader()
    refused = call("get", path, token)
    assert refused.status_code == 402 and refused.json()["code"] == "subscription_required"
    p = plan()
    Subscription.objects.create(
        reader=user,
        plan=p,
        starts_at=timezone.now(),
        ends_at=timezone.now() + timedelta(days=1),
        payment=Payment.objects.create(reader=user, plan=p, method="mobile", amount=1, currency="TZS"),
    )
    whole = call("get", path, token)
    assert whole.status_code == 200 and "no-store" in whole["Cache-Control"]
    assert whole.json()["locked"] is False and len(whole.json()["body"]["blocks"]) == 6


def test_turning_the_lock_off_opens_every_story(editor):
    from newsplatform.site_config.models import SettingsSection

    pub = story(editor, True)
    SettingsSection.objects.create(key="subscriptions", data={"enabled": False}, version=1)
    assert Client().get(API + f"content/articles/{pub.slug}?locale=sw").json()["locked"] is False


def test_paying_by_phone_adds_a_month_once_and_a_second_payment_adds_after_it(editor, monkeypatch):
    user, token = reader()
    offer = call("get", "subscriptions/plans?locale=en").json()
    assert offer["methods"] == ["mobile", "card"] and len(offer["plans"]) == 6
    month = next(p for p in offer["plans"] if p["interval"] == "month" and p["highlighted"])
    assert month["name"] == "Standard" and month["badge"] == "Most popular"
    started = pay(token, Plan.objects.get(pk=month["id"]))
    assert started["status"] == "pending"
    # The reader approves on the phone; locally that is a few seconds later.
    Payment.objects.filter(pk=started["id"]).update(created_at=timezone.now() - timedelta(seconds=10))
    done = call("get", f"subscriptions/payments/{started['id']}", token).json()
    assert done["status"] == "completed" and done["subscription"]["active"] is True
    first = Subscription.objects.get(reader=user)
    # Snippe saying it again changes nothing.
    services.settle(Payment.objects.get(pk=started["id"]).reference, "completed")
    assert Subscription.objects.filter(reader=user).count() == 1
    again = pay(token, Plan.objects.get(pk=month["id"]))
    services.settle(Payment.objects.get(pk=again["id"]).reference, "completed")
    second = Subscription.objects.filter(reader=user).latest("ends_at")
    assert second.starts_at == first.ends_at


def test_a_month_ends_on_the_same_day_or_the_last_of_a_short_month():
    assert services.add_period(datetime(2026, 1, 31, tzinfo=UTC), "month") == datetime(
        2026, 2, 28, tzinfo=UTC
    )
    assert services.add_period(datetime(2026, 11, 28, tzinfo=UTC), "month") == datetime(
        2026, 12, 28, tzinfo=UTC
    )
    assert services.add_period(datetime(2026, 12, 5, tzinfo=UTC), "month") == datetime(2027, 1, 5, tzinfo=UTC)
    assert services.add_period(datetime(2028, 2, 29, tzinfo=UTC), "year") == datetime(2029, 2, 28, tzinfo=UTC)


def test_only_tanzanian_mobiles_and_listed_ways_of_paying(editor):
    _, token = reader()
    p = plan()
    r = call(
        "post",
        "subscriptions/checkout",
        token,
        {"plan": str(p.pk), "method": "mobile", "phone": "+447700900123"},
    )
    assert r.status_code == 400 and r.json()["field"] == "phone"
    r = call("post", "subscriptions/checkout", token, {"plan": str(p.pk), "method": "bitcoin"})
    assert r.status_code == 400


def test_another_readers_payment_is_not_found():
    _, mine = reader()
    _, theirs = reader("+255712000002")
    started = pay(mine, plan())
    assert call("get", f"subscriptions/payments/{started['id']}", theirs).status_code == 404


# ---- Snippe ----
def _config() -> snippe.SnippeConfig:
    return snippe.SnippeConfig(
        api_key="snp_test_key_0123456789",
        webhook_secret=SECRET,
        webhook_url="https://api.example.co.tz/api/v1/subscriptions/webhook",
        card_token="jwt-token-for-sessions",
    )


def _signed(
    event: dict[str, Any], when: int | None = None, secret: str = SECRET
) -> tuple[bytes, dict[str, str]]:
    raw = json.dumps(event).encode()
    stamp = str(when or int(time.time()))
    sig = hmac.new(secret.encode(), stamp.encode() + b"." + raw, hashlib.sha256).hexdigest()
    return raw, {"X-Webhook-Timestamp": stamp, "X-Webhook-Signature": sig}


def test_the_push_is_sent_as_snippe_documents_it(monkeypatch):
    sent: dict[str, Any] = {}

    def fake(url: str, **kw: Any) -> httpx.Response:
        sent.update(url=url, **kw)
        return httpx.Response(
            201, json={"status": "success", "data": {"reference": "9015c155", "status": "pending"}}
        )

    monkeypatch.setattr(httpx, "post", fake)
    made = snippe.push(
        _config(),
        key="a" * 40,
        amount=5000,
        phone="+255712000001",
        customer={"firstname": "Asha", "lastname": "Juma", "email": ""},
        metadata={"payment": "x"},
    )
    assert made["reference"] == "9015c155"
    assert sent["url"] == "https://api.snippe.sh/v1/payments"
    assert sent["headers"]["Authorization"] == "Bearer snp_test_key_0123456789"
    assert len(sent["headers"]["Idempotency-Key"]) == 30
    assert sent["json"]["payment_type"] == "mobile" and sent["json"]["phone_number"] == "255712000001"
    assert sent["json"]["details"] == {"amount": 5000, "currency": "TZS"}


def test_only_a_recent_webhook_signed_by_snippe_completes_a_payment(monkeypatch):
    monkeypatch.setattr(services, "snippe", _config)
    user, _ = reader()
    payment = Payment.objects.create(
        reader=user, plan=plan(), method="mobile", amount=5000, currency="TZS", reference="pi_abc123"
    )
    event = {
        "id": "evt_1",
        "type": "payment.completed",
        "data": {"reference": "pi_abc123", "status": "completed"},
    }
    raw, headers = _signed(event, secret="whsec_someone_else")
    assert services.webhook(raw, headers) is False
    raw, headers = _signed(event, when=int(time.time()) - 600)
    assert services.webhook(raw, headers) is False
    raw, headers = _signed(event)
    hook = Client().post(
        API + "subscriptions/webhook",
        raw,
        content_type="application/json",
        HTTP_X_WEBHOOK_TIMESTAMP=headers["X-Webhook-Timestamp"],
        HTTP_X_WEBHOOK_SIGNATURE=headers["X-Webhook-Signature"],
    )
    assert hook.status_code == 204
    payment.refresh_from_db()
    assert payment.status == "completed" and Subscription.objects.filter(reader=user).count() == 1
    assert services.webhook(raw, headers) is True  # the same event again: nothing more
    assert Subscription.objects.filter(reader=user).count() == 1


def test_a_failed_payment_adds_no_time():
    user, _ = reader()
    p = Payment.objects.create(
        reader=user, plan=plan(), method="mobile", amount=5000, currency="TZS", reference="r1"
    )
    services.settle("r1", "failed")
    p.refresh_from_db()
    assert p.status == "failed" and not Subscription.objects.filter(reader=user).exists()


def test_the_newsroom_shapes_its_plans(admin_api, settings):
    settings.ROOT_URLCONF = "config.urls_admin"
    _, a = admin_api("admin")
    made = a.post(
        "subscriptions/plans",
        {
            "code": "students-month",
            "interval": "month",
            "price": 1500,
            "name_sw": "Wanafunzi",
            "name_en": "Students",
            "features_en": ["Every subscriber story"],
            "tone": "forest",
        },
    )
    assert made.status_code == 201, made.content
    assert (
        a.post(
            "subscriptions/plans",
            {"code": "cheap", "interval": "month", "price": 100, "name_sw": "x", "name_en": "x"},
        ).status_code
        == 400
    )
    assert a.get("subscriptions/summary").json()["subscribers"] == 0
