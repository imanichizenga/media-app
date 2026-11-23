import base64
import json
from typing import Any

import pyotp
import pytest
from django.db import connection
from django.test import Client

from newsplatform.accounts.models import User
from newsplatform.common import context
from newsplatform.common.redis import cache
from newsplatform.rbac.models import Role
from newsplatform.rbac.services import assign_role, sync_system_roles
from newsplatform.staff_security import passwords

PASSWORD = "correct horse battery staple"
ORIGIN = "http://localhost:3001"
UA = "Mozilla/5.0 (X11; Linux x86_64) Chrome/140.0 Safari/537.36"


@pytest.fixture(autouse=True)
def _isolate(monkeypatch: Any):
    cache().flushdb()
    context.set_context(None)
    # Never call the real breach service from tests; its own tests drive the parser directly.
    monkeypatch.setattr(passwords, "_breach_count", lambda p: 0)
    from newsplatform.integrations import services

    services._cache.clear()
    monkeypatch.setattr(services, "_ensure_listener", lambda: None)
    yield
    context.set_context(None)


@pytest.fixture
def roles(db):
    sync_system_roles()
    return {r.key: r for r in Role.objects.all()}


@pytest.fixture
def make_staff(roles):
    def make(role: str = "super_admin", email: str | None = None) -> User:
        from django.db import transaction

        email = email or f"{role}-{User.objects.count()}@example.test"
        user = User.objects.create_user(email=email, password=PASSWORD, display_name=role.title())
        with transaction.atomic():
            assign_role(actor=None, user=user, role=roles[role])
        user.refresh_from_db()
        return user

    return make


class Api:
    """A browser-like client: origin header, cookie jar, CSRF token."""

    def __init__(self, ua: str = UA, ip: str = "203.0.113.5") -> None:
        self.client, self.csrf, self.ua, self.ip, self.origin = Client(), "", ua, ip, ORIGIN
        self.totp: pyotp.TOTP | None = None
        self.codes: list[str] = []

    def request(self, method: str, path: str, data: Any = None, **headers: str):
        h = {"user-agent": self.ua, "x-csrf-token": self.csrf, "origin": self.origin, **headers}
        res = self.client.generic(
            method,
            f"/api/v1/{path}",
            json.dumps(data) if data is not None else "",
            content_type="application/json",
            headers={k: v for k, v in h.items() if v},
            REMOTE_ADDR=self.ip,
        )
        if res.headers.get("content-type", "").startswith("application/json"):
            body = res.json()
            found = body.get("session", body) if isinstance(body, dict) else {}
            self.csrf = found.get("csrf_token", self.csrf)
        return res

    def get(self, path: str, **h: str):
        return self.request("GET", path, **h)

    def post(self, path: str, data: Any = None, **h: str):
        return self.request("POST", path, {} if data is None else data, **h)

    def put(self, path: str, data: Any, **h: str):
        return self.request("PUT", path, data, **h)

    def delete(self, path: str, **h: str):
        return self.request("DELETE", path, **h)

    def login(self, user: User, password: str = PASSWORD):
        return self.post("auth/login", {"email": user.email, "password": password})

    def enrol_totp(self):
        begin = self.post("auth/mfa/totp/begin")
        assert begin.status_code == 200, begin.content
        self.totp = pyotp.TOTP(begin.json()["secret"])
        res = self.post("auth/mfa/totp/confirm", {"code": self.totp.now()})
        assert res.status_code == 200, res.content
        self.codes = res.json()["recovery_codes"]
        return res

    def sign_in(self, user: User) -> Api:
        assert self.login(user).status_code == 200
        self.enrol_totp()
        return self


@pytest.fixture
def api():
    return Api()


@pytest.fixture
def new_api():
    return Api


@pytest.fixture
def admin_api(make_staff, new_api):
    def make(role: str = "super_admin"):
        user = make_staff(role)
        return user, new_api().sign_in(user)

    return make


@pytest.fixture
def tamper(db):
    """Act as an attacker with owner access to the database."""

    def run(sql: str, *params: Any) -> None:
        with connection.cursor() as cur:
            cur.execute("ALTER TABLE audit_auditentry DISABLE TRIGGER USER")
            cur.execute(sql, params)
            cur.execute("SET CONSTRAINTS ALL IMMEDIATE")
            cur.execute("ALTER TABLE audit_auditentry ENABLE TRIGGER USER")

    return run


def b64(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()
