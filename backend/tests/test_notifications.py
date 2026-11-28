"""Web Push (ADR-0051): what a browser receives decrypts as the standard says, only push services are ever
written to, and readers hear of a story once, when it is first published."""

import json
from typing import Any

import httpx
import pytest
from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from django.test import Client

from newsplatform.content import tasks as content_tasks
from newsplatform.notifications import services, webpush
from newsplatform.notifications.models import PushSubscription
from newsplatform.site_config.models import SettingsSection
from tests import factories as f

pytestmark = pytest.mark.django_db
API = "/api/v1/"
FCM = "https://fcm.googleapis.com/fcm/send/abc123"


@pytest.fixture(autouse=True)
def _public(settings, monkeypatch):
    settings.ROOT_URLCONF = "config.urls_public"
    settings.MIDDLEWARE = [m for m in settings.MIDDLEWARE if "IpAllowlist" not in m]
    monkeypatch.setattr(content_tasks.announce, "delay", lambda tags, pages: None)


class Browser:
    """What a browser holds for one subscription, and how it opens a message (RFC 8291, receiving side)."""

    def __init__(self) -> None:
        self.key = ec.generate_private_key(ec.SECP256R1())
        self.public = self.key.public_key().public_bytes(
            serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint
        )
        self.secret = b"0123456789abcdef"

    @property
    def keys(self) -> dict[str, str]:
        return {"p256dh": webpush.b64u(self.public), "auth": webpush.b64u(self.secret)}

    def open(self, body: bytes) -> bytes:
        salt, size, n = body[:16], int.from_bytes(body[16:20], "big"), body[20]
        server = body[21 : 21 + n]
        assert size == 4096 and n == 65
        shared = self.key.exchange(
            ec.ECDH(), ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), server)
        )

        def kdf(salt: bytes, ikm: bytes, info: bytes, length: int) -> bytes:
            return HKDF(algorithm=hashes.SHA256(), length=length, salt=salt, info=info).derive(ikm)

        ikm = kdf(self.secret, shared, b"WebPush: info\x00" + self.public + server, 32)
        cek = kdf(salt, ikm, b"Content-Encoding: aes128gcm\x00", 16)
        nonce = kdf(salt, ikm, b"Content-Encoding: nonce\x00", 12)
        plain = AESGCM(cek).decrypt(nonce, body[21 + n :], None)
        assert plain.endswith(b"\x02")
        return plain[:-1]


def test_a_message_opens_in_the_browser_it_was_sealed_for():
    browser = Browser()
    sealed = webpush.encrypt(b'{"title":"Habari"}', **browser.keys)
    assert browser.open(sealed) == b'{"title":"Habari"}'
    assert webpush.encrypt(b"x", **browser.keys) != webpush.encrypt(
        b"x", **browser.keys
    )  # a new key each time
    with pytest.raises(InvalidTag):
        Browser().open(sealed)  # another browser cannot


def test_the_signature_is_for_the_push_service_and_checks_with_the_public_key():
    public, private = webpush.new_key()
    header = webpush.vapid(FCM, private, public, "mailto:newsroom@example.test")
    token = header.split("t=")[1].split(",")[0]
    head, claims, signature = token.split(".")
    assert json.loads(webpush.unb64u(claims))["aud"] == "https://fcm.googleapis.com"
    raw = webpush.unb64u(signature)
    key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), webpush.unb64u(public))
    der = encode_dss_signature(int.from_bytes(raw[:32], "big"), int.from_bytes(raw[32:], "big"))
    key.verify(der, f"{head}.{claims}".encode(), ec.ECDSA(hashes.SHA256()))
    assert header.endswith(f"k={public}")


@pytest.mark.parametrize(
    "endpoint",
    [
        "http://fcm.googleapis.com/x",  # not https
        "https://evil.example/x",
        "https://fcm.googleapis.com.evil.example/x",
        "https://fcm.googleapis.com:8443/x",
        "https://user:pw@fcm.googleapis.com/x",
        "https://169.254.169.254/latest/meta-data",
    ],
)
def test_only_push_services_are_ever_written_to(endpoint):
    res = Client().post(
        API + "push/subscriptions",
        {"endpoint": endpoint, "keys": Browser().keys},
        content_type="application/json",
    )
    assert res.status_code == 400 and PushSubscription.objects.count() == 0


def test_a_browser_subscribes_once_and_can_leave():
    browser = Browser()
    for _ in range(2):
        res = Client().post(
            API + "push/subscriptions",
            {"endpoint": "https://web.push.apple.com/QGk", "keys": browser.keys, "locale": "en"},
            content_type="application/json",
        )
        assert res.status_code == 204
    assert PushSubscription.objects.get().locale == "en"
    key = Client().get(API + "push/key").json()
    assert key["enabled"] is True and len(webpush.unb64u(key["public_key"])) == 65
    Client().delete(
        API + "push/subscriptions",
        {"endpoint": "https://web.push.apple.com/QGk"},
        content_type="application/json",
    )
    assert PushSubscription.objects.count() == 0


def test_bad_keys_are_refused():
    res = Client().post(
        API + "push/subscriptions",
        {"endpoint": FCM, "keys": {"p256dh": "short", "auth": "x"}},
        content_type="application/json",
    )
    assert res.status_code == 400


@pytest.fixture
def sent(monkeypatch):
    """Every message a push service would have received, opened as its browser would."""
    browsers: dict[str, Browser] = {}
    got: list[tuple[str, dict[str, Any]]] = []
    status = {"code": 201}

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.headers["authorization"].startswith("vapid t=")
        assert request.headers["content-encoding"] == "aes128gcm"
        got.append((str(request.url), json.loads(browsers[str(request.url)].open(request.content))))
        return httpx.Response(status["code"])

    real = httpx.Client

    def client(**kw: Any) -> httpx.Client:
        return real(transport=httpx.MockTransport(handler), **kw)

    monkeypatch.setattr(services.httpx, "Client", client)

    def subscribe(endpoint: str, locale: str = "sw") -> None:
        browsers[endpoint] = Browser()
        services.subscribe({"endpoint": endpoint, "keys": browsers[endpoint].keys, "locale": locale})

    return got, subscribe, status


def test_readers_hear_of_a_story_once_when_it_is_first_published(
    make_staff, sent, django_capture_on_commit_callbacks
):
    got, subscribe, _ = sent
    subscribe(FCM)
    subscribe("https://updates.push.services.mozilla.com/wpush/v2/x", "en")
    editor = make_staff("editor_in_chief")
    row = f.post(editor, f.category("habari"), "Mvua kubwa Dodoma")
    with django_capture_on_commit_callbacks(execute=True):
        row = f.go(editor, row, "publish")
    assert [(url, m["body"], m["url"]) for url, m in got] == [
        (FCM, "Mvua kubwa Dodoma", row.publications.get().path)
    ]
    with django_capture_on_commit_callbacks(execute=True):
        f.go(editor, row, "unpublish", "publish")  # back again: not news twice
    assert len(got) == 1


def test_the_newsroom_can_switch_notifications_off(make_staff, sent, django_capture_on_commit_callbacks):
    got, subscribe, _ = sent
    subscribe(FCM)
    SettingsSection.objects.update_or_create(
        key="engagement", defaults={"data": {"push_new_stories": False}, "version": 2}
    )
    from django.core.cache import cache

    cache.clear()
    editor = make_staff("editor_in_chief")
    with django_capture_on_commit_callbacks(execute=True):
        f.go(editor, f.post(editor, f.category("habari"), "Habari"), "publish")
    assert got == [] and Client().get(API + "push/key").json() == {"enabled": False, "public_key": ""}


def test_a_subscription_the_service_calls_gone_is_forgotten(
    make_staff, sent, django_capture_on_commit_callbacks
):
    _got, subscribe, status = sent
    subscribe(FCM)
    status["code"] = 410
    editor = make_staff("editor_in_chief")
    with django_capture_on_commit_callbacks(execute=True):
        f.go(editor, f.post(editor, f.category("habari"), "Habari"), "publish")
    assert PushSubscription.objects.count() == 0


def test_the_private_key_is_kept_sealed():
    from newsplatform.notifications.models import PushKey

    public, private = services.keys()
    assert services.keys() == (public, private)  # made once
    assert "c" in PushKey.objects.get().private and webpush.b64u(private) not in json.dumps(
        PushKey.objects.get().private
    )
