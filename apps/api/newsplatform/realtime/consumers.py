import asyncio
import contextlib
from typing import Any

import structlog
from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.conf import settings
from django.http import parse_cookie

from newsplatform.common.middleware import resolve_ip
from newsplatform.realtime import tickets, topics
from newsplatform.realtime.topics import Topic
from newsplatform.site_config.services import get_security, ip_allowed
from newsplatform.staff_security import sessions
from newsplatform.staff_security.models import StaffSession

log = structlog.get_logger(__name__)
AUTH_SECONDS = 5
REVALIDATE_SECONDS = 10
MAX_TOPICS = 20
BAD_MESSAGE, SIGNED_OUT, FORBIDDEN, AUTH_TIMEOUT = 4400, 4401, 4403, 4408


class StaffConsumer(AsyncJsonWebsocketConsumer):
    """Signals only. Handshake: Origin, allowlist, cookie. First message: a single-use ticket (ADR-0020)."""

    session: StaffSession | None
    ticketed: bool
    topics: set[Topic]
    watchdog: asyncio.Task[None] | None

    async def connect(self) -> None:
        self.session, self.ticketed, self.topics, self.watchdog = None, False, set(), None
        headers = {k.decode("latin-1").lower(): v.decode("latin-1") for k, v in self.scope["headers"]}
        # Browsers always send Origin here, and cookies cross sites without it being checked by anyone else.
        if headers.get("origin") != settings.ADMIN_ORIGIN:
            return await self.close()
        remote = (self.scope.get("client") or ("", 0))[0]
        ip = resolve_ip(remote, headers.get("x-forwarded-for", ""))
        token = parse_cookie(headers.get("cookie", "")).get(settings.STAFF_COOKIE_NAME, "")
        self.session = await self._admit(token, ip)
        if self.session is None:
            return await self.close()
        await self.accept()
        self.watchdog = asyncio.create_task(self._watch(ip))

    async def disconnect(self, code: int) -> None:
        if self.watchdog:
            self.watchdog.cancel()
        for topic in self.topics:
            # The layer may be the reason we are closing.
            with contextlib.suppress(Exception):
                await self.channel_layer.group_discard(topic.group, self.channel_name)

    async def receive(
        self, text_data: str | None = None, bytes_data: bytes | None = None, **kwargs: Any
    ) -> None:
        try:
            await super().receive(text_data=text_data, bytes_data=bytes_data, **kwargs)
        except ValueError:  # not JSON, or a binary frame
            await self.close(code=BAD_MESSAGE)

    async def receive_json(self, content: Any, **kwargs: Any) -> None:
        kind = content.get("type") if isinstance(content, dict) else None
        if kind == "auth":
            return await self._authenticate(content.get("ticket"))
        if not self.ticketed:
            return await self.close(code=SIGNED_OUT)
        topic = topics.parse(content.get("topic")) if kind in ("subscribe", "unsubscribe") else None
        if topic is None:
            return await self.close(code=BAD_MESSAGE)
        if kind == "unsubscribe":
            if topic in self.topics:
                self.topics.discard(topic)
                await self.channel_layer.group_discard(topic.group, self.channel_name)
            return None
        if not await self._may(topic) or len(self.topics) >= MAX_TOPICS:
            return await self.send_json({"type": "refused", "topic": str(topic)})
        await self.channel_layer.group_add(topic.group, self.channel_name)
        self.topics.add(topic)
        # The client refetches on this: anything published before the group existed is covered.
        await self.send_json({"type": "subscribed", "topic": str(topic)})

    async def topic_changed(self, event: dict[str, Any]) -> None:
        await self.send_json({"type": "changed", "topic": event["topic"]})

    async def _authenticate(self, ticket: object) -> None:
        owner = await database_sync_to_async(tickets.consume)(ticket) if isinstance(ticket, str) else None
        if self.session is None or owner != str(self.session.pk):
            return await self.close(code=SIGNED_OUT)
        self.ticketed = True
        await self.send_json({"type": "ready"})

    async def _watch(self, ip: str | None) -> None:
        """Sign-out, timeouts, disabled accounts, allowlist and permission changes reach open sockets."""
        await asyncio.sleep(AUTH_SECONDS)
        if not self.ticketed:
            return await self.close(code=AUTH_TIMEOUT)
        while True:
            await asyncio.sleep(REVALIDATE_SECONDS)
            try:
                state = await self._still_valid(ip)
            except Exception as exc:
                # Fail closed: without the database nobody can prove this session is still good.
                log.warning("realtime_revalidate_failed", error=type(exc).__name__)
                state = SIGNED_OUT
            if state:
                return await self.close(code=state)

    @database_sync_to_async
    def _admit(self, token: str, ip: str | None) -> StaffSession | None:
        if not token or not ip_allowed(ip, get_security()):
            return None
        session = sessions.find(token)
        return session if session and self._good(session) else None

    @staticmethod
    def _good(session: StaffSession) -> bool:
        return session.is_active_stage and sessions.ended_because(session) is None

    @database_sync_to_async
    def _still_valid(self, ip: str | None) -> int:
        assert self.session is not None  # noqa: S101 (type narrowing)
        session = sessions.find_by_id(self.session.pk)
        if session is None or not self._good(session):
            return SIGNED_OUT
        if not ip_allowed(ip, get_security()):
            return FORBIDDEN
        return 0 if all(topics.allowed(session.user, t) for t in self.topics) else FORBIDDEN

    @database_sync_to_async
    def _may(self, topic: Topic) -> bool:
        assert self.session is not None  # noqa: S101 (type narrowing)
        return topics.allowed(self.session.user, topic)
