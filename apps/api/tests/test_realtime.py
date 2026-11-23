import asyncio
import json

import pytest
from channels.db import database_sync_to_async
from django.conf import settings

from config.asgi_realtime import application
from newsplatform.common.redis import cache
from newsplatform.integrations.models import IntegrationTestRun
from newsplatform.realtime import consumers, publish, tickets, topics
from newsplatform.staff_security.models import StaffSession
from tests.conftest import ORIGIN
from tests.websocket import WebSocket

pytestmark = [
    pytest.mark.django_db(transaction=True),
    pytest.mark.usefixtures("allow_flush"),
    pytest.mark.asyncio,
]
TOPIC = "integration_test:0197a000-0000-7000-8000-000000000001"


class Person:
    def __init__(self, user, api):
        self.user, self.api = user, api
        self.cookie = api.client.cookies[settings.STAFF_COOKIE_NAME].value

    def ticket(self) -> str:
        return self.api.post("realtime/ticket").json()["ticket"]

    async def open(self, origin: str | None = ORIGIN, cookie: str | None = None, ip: str = "203.0.113.5"):
        headers = [(b"cookie", f"{settings.STAFF_COOKIE_NAME}={cookie or self.cookie}".encode())]
        if origin:
            headers.append((b"origin", origin.encode()))
        ws = WebSocket(application, "/ws/v1/staff", headers, ip)
        return ws, await ws.connect()

    async def ready(self):
        ws, accepted = await self.open()
        assert accepted
        await ws.send_json({"type": "auth", "ticket": await database_sync_to_async(self.ticket)()})
        assert await ws.receive_json() == {"type": "ready"}
        return ws

    async def subscribed(self, topic: str = TOPIC):
        ws = await self.ready()
        await ws.send_json({"type": "subscribe", "topic": topic})
        assert await ws.receive_json() == {"type": "subscribed", "topic": topic}
        return ws


@pytest.fixture
def person(admin_api):
    return lambda role="super_admin": Person(*admin_api(role))


@pytest.fixture
def admin(person):
    return person()


@pytest.fixture
def journalist(person):
    return person("journalist")


@pytest.fixture
def quick(monkeypatch):
    monkeypatch.setattr(consumers, "AUTH_SECONDS", 0.1)
    monkeypatch.setattr(consumers, "REVALIDATE_SECONDS", 0.1)


@database_sync_to_async
def announce(topic: str = TOPIC) -> None:
    parsed = topics.parse(topic)
    publish.changed(parsed.kind, parsed.id)


async def test_subscriber_is_told_what_changed_and_nothing_else(admin):
    ws = await admin.subscribed()
    await announce()
    assert await ws.receive_json() == {"type": "changed", "topic": TOPIC}
    await ws.disconnect()


@pytest.mark.parametrize(
    "origin", [None, "https://evil.example", "http://localhost:3001.evil.example", "null"]
)
async def test_cross_site_socket_is_refused(admin, origin):
    _, accepted = await admin.open(origin=origin)
    assert not accepted


async def test_no_session_is_refused(admin):
    _, accepted = await admin.open(cookie="not-a-session")
    assert not accepted


async def test_half_open_session_is_refused(make_staff, new_api):
    user = await database_sync_to_async(make_staff)()
    api = new_api()
    assert (await database_sync_to_async(api.login)(user)).status_code == 200
    _, accepted = await Person(user, api).open()
    assert not accepted


async def test_allowlist_applies_to_sockets(admin, monkeypatch):
    monkeypatch.setattr(consumers, "ip_allowed", lambda ip, _: ip == "203.0.113.5")
    _, accepted = await admin.open(ip="198.51.100.9")
    assert not accepted
    _, accepted = await admin.open()
    assert accepted


async def test_nothing_works_before_the_ticket(admin):
    ws, _ = await admin.open()
    await ws.send_json({"type": "subscribe", "topic": TOPIC})
    assert await ws.closed_with() == consumers.SIGNED_OUT


async def test_ticket_is_single_use(admin):
    ticket = await database_sync_to_async(admin.ticket)()
    ws, _ = await admin.open()
    await ws.send_json({"type": "auth", "ticket": ticket})
    assert await ws.receive_json() == {"type": "ready"}
    again, _ = await admin.open()
    await again.send_json({"type": "auth", "ticket": ticket})
    assert await again.closed_with() == consumers.SIGNED_OUT


async def test_ticket_of_another_session_is_refused(admin, journalist):
    """A stolen cookie alone is not enough: its ticket can only be issued to the device it belongs to."""
    ws, _ = await admin.open()
    ticket = await database_sync_to_async(journalist.ticket)()
    await ws.send_json({"type": "auth", "ticket": ticket})
    assert await ws.closed_with() == consumers.SIGNED_OUT


@pytest.mark.parametrize("ticket", [None, 7, "", {"a": 1}])
async def test_malformed_ticket(admin, ticket):
    ws, _ = await admin.open()
    await ws.send_json({"type": "auth", "ticket": ticket})
    assert await ws.closed_with() == consumers.SIGNED_OUT


async def test_tickets_expire_and_are_stored_hashed(admin):
    ticket = await database_sync_to_async(admin.ticket)()
    keys = await database_sync_to_async(lambda: list(cache().keys("ws:ticket:*")))()
    assert len(keys) == 1
    assert ticket not in keys[0]
    assert 0 < await database_sync_to_async(cache().ttl)(keys[0]) <= tickets.TTL_SECONDS


async def test_silent_client_is_dropped(admin, quick):
    ws, _ = await admin.open()
    assert await ws.closed_with() == consumers.AUTH_TIMEOUT


async def test_topic_needs_its_permission(journalist):
    ws = await journalist.ready()
    await ws.send_json({"type": "subscribe", "topic": TOPIC})
    assert await ws.receive_json() == {"type": "refused", "topic": TOPIC}
    await announce()
    assert await ws.receive_nothing(0.5)
    await ws.disconnect()


@pytest.mark.parametrize(
    "message",
    [
        {"type": "subscribe", "topic": "unknown:0197a000-0000-7000-8000-000000000001"},
        {"type": "subscribe", "topic": "integration_test:*"},
        {"type": "subscribe", "topic": ["integration_test"]},
        {"type": "subscribe"},
        {"type": "topic.changed", "topic": TOPIC},
        {"type": ["subscribe"]},
        ["subscribe"],
        7,
        None,
    ],
)
async def test_malformed_messages_close_the_socket(admin, message):
    ws = await admin.ready()
    await ws.send_json(message)
    assert await ws.closed_with() == consumers.BAD_MESSAGE


async def test_text_that_is_not_json_and_binary_frames(admin):
    ws = await admin.ready()
    await ws.send_text("{nope")
    assert await ws.closed_with() == consumers.BAD_MESSAGE
    ws = await admin.ready()
    await ws.send_bytes(b"\x00\xff")
    assert await ws.closed_with() == consumers.BAD_MESSAGE


async def test_unsubscribe_stops_signals(admin):
    ws = await admin.subscribed()
    await ws.send_json({"type": "unsubscribe", "topic": TOPIC})
    await asyncio.sleep(0.3)
    await announce()
    assert await ws.receive_nothing(0.5)
    await ws.disconnect()


async def test_number_of_topics_is_capped(admin, monkeypatch):
    monkeypatch.setattr(consumers, "MAX_TOPICS", 1)
    ws = await admin.subscribed()
    other = TOPIC[:-1] + "2"
    await ws.send_json({"type": "subscribe", "topic": other})
    assert await ws.receive_json() == {"type": "refused", "topic": other}
    await ws.disconnect()


@pytest.mark.parametrize("reason", ["revoked", "disabled", "idle", "expired"])
async def test_an_ended_session_closes_open_sockets(admin, quick, reason):
    from datetime import timedelta

    from django.utils import timezone

    ws = await admin.subscribed()

    @database_sync_to_async
    def end():
        long_ago = timezone.now() - timedelta(days=2)
        rows = StaffSession.objects.filter(user=admin.user)
        if reason == "revoked":
            rows.update(revoked_at=timezone.now())
        elif reason == "idle":
            rows.update(last_seen_at=long_ago)
        elif reason == "expired":
            rows.update(expires_at=long_ago)
        else:
            type(admin.user).objects.filter(pk=admin.user.pk).update(status="suspended")

    await end()
    assert await ws.closed_with() == consumers.SIGNED_OUT


async def test_losing_the_permission_closes_open_sockets(admin, quick, monkeypatch):
    ws = await admin.subscribed()
    monkeypatch.setattr(topics, "allowed", lambda *_: False)
    assert await ws.closed_with() == consumers.FORBIDDEN


async def test_an_open_socket_does_not_keep_the_session_alive(admin, quick):
    seen = database_sync_to_async(lambda: StaffSession.objects.get(user=admin.user).last_seen_at)
    ws = await admin.ready()
    before = await seen()
    await asyncio.sleep(0.5)
    assert await seen() == before
    await ws.disconnect()


async def test_fingerprint_is_not_checked_on_the_handshake(admin):
    """Browsers omit Sec-CH-UA-* on WebSocket handshakes; checking there would sign staff out."""
    await admin.ready()
    session = await database_sync_to_async(StaffSession.objects.get)(user=admin.user)
    assert session.revoked_at is None


async def test_a_failed_publish_never_breaks_the_producer(monkeypatch):
    class Broken:
        async def group_send(self, *_):
            raise ConnectionError

    monkeypatch.setattr(publish, "get_channel_layer", lambda: Broken())
    await announce()


async def test_publishing_many_times_leaks_no_connections():
    count = database_sync_to_async(lambda: len(publish_clients()))
    await announce()
    before = await count()
    for _ in range(30):
        await announce()
    assert await count() <= before + 2


def publish_clients():
    from newsplatform.common.redis import bus

    return bus().client_list()


async def test_integration_test_signals_progress(admin, monkeypatch):
    from newsplatform.integrations import services
    from tests.test_integrations import save

    @database_sync_to_async
    def queued():
        save(admin.api)
        monkeypatch.setattr("newsplatform.integrations.tasks.run_test.delay", lambda *_: None)
        res = admin.api.post("integrations/aws_s3/versions/1/test", {"params": {}})
        assert res.status_code == 202, res.content
        return IntegrationTestRun.objects.get()

    run = await queued()
    topic = f"integration_test:{run.pk}"
    ws = await admin.subscribed(topic)
    monkeypatch.setattr(services, "get_provider", lambda _: FakeProvider())
    await database_sync_to_async(services.execute_test)(str(run.pk))
    signals = []
    while not await ws.receive_nothing(0.5):
        signals.append(await ws.receive_json())
    assert len(signals) >= 3, signals
    assert all(s == {"type": "changed", "topic": topic} for s in signals)
    await ws.disconnect()


class FakeProvider:
    def test(self, config, test, params):
        test.step("probe", "Probe", "Jaribu", lambda: "ok")

    class config_model:
        @staticmethod
        def model_validate(_):
            return object()


async def test_realtime_process_serves_health_and_no_api():
    from django.urls import resolve
    from django.urls.exceptions import Resolver404

    assert resolve("/health/ready", urlconf="config.urls_realtime").func.__name__ == "ready_realtime"
    with pytest.raises(Resolver404):
        resolve("/api/v1/auth/session", urlconf="config.urls_realtime")


async def test_readiness_follows_the_channel_layer(client, monkeypatch, settings):
    from newsplatform.common import health

    settings.ROOT_URLCONF = "config.urls_realtime"
    get = database_sync_to_async(client.get)
    assert (await get("/health/ready")).status_code == 200

    class Down:
        def ping(self):
            import redis

            raise redis.ConnectionError

    monkeypatch.setattr(health, "bus", Down)
    res = await get("/health/ready")
    assert res.status_code == 503
    assert json.loads(res.content)["checks"] == {"database": True, "channel_layer": False}
