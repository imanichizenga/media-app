import re
import socket

import pytest
from django.test import RequestFactory
from django.urls import get_resolver

from newsplatform.common import http
from newsplatform.common.errors import RateLimited
from newsplatform.common.logging import redact, redact_text
from newsplatform.common.middleware import client_ip
from newsplatform.common.ratelimit import Limit, check
from newsplatform.content.public_api import PublicView

ANONYMOUS = {"LoginView", "AcceptInviteView", "CompleteResetView"}


def _views():
    for p in get_resolver("config.urls_admin").url_patterns:
        cls = getattr(p.callback, "view_class", None)
        if cls:
            yield str(p.pattern), cls


def test_every_admin_endpoint_declares_its_access():
    """Deny by default: a method without a declared rule must not exist."""
    from newsplatform.common.api import AnonymousStaffView, StaffView
    from newsplatform.rbac.registry import PERMISSIONS
    from newsplatform.staff_security.api import AnyStageView

    for path, cls in _views():
        if issubclass(cls, AnonymousStaffView):
            assert cls.__name__ in ANONYMOUS, path
        elif issubclass(cls, AnyStageView):
            assert path.startswith("api/v1/auth/"), path
        else:
            assert issubclass(cls, StaffView), path
            methods = {m.upper() for m in ("get", "post", "put", "patch", "delete") if hasattr(cls, m)}
            assert methods == set(cls.perms), path
            assert {p for p in cls.perms.values() if p} <= PERMISSIONS.keys(), path


@pytest.mark.django_db
def test_no_endpoint_answers_anonymously(new_api):
    for path, cls in _views():
        if cls.__name__ in ANONYMOUS:
            continue
        url = path.replace("api/v1/", "").replace("<slug:key>", "aws_s3").replace("<int:number>", "1")
        url = re.sub(r"<uuid:\w+>", "0198c000-0000-7000-8000-000000000000", url)
        if "(?P" in url:
            continue
        for method in ("get", "post", "put", "patch", "delete"):
            if hasattr(cls, method):
                assert new_api().request(method.upper(), url).status_code in (401, 403), (method, url)


def test_public_surface_has_no_admin_routes():
    """Every public address is listed here on purpose, and can only be read."""
    patterns = get_resolver("config.urls_public").url_patterns
    content = {
        str(p.pattern).removeprefix("api/v1/content/") for p in patterns if "/content/" in str(p.pattern)
    }
    rest = {str(p.pattern) for p in patterns if "/content/" not in str(p.pattern)}
    theme = {p.strip("^").split("theme/")[1].split("(")[0] for p in rest if "theme/" in p}
    assert theme == {"", "current.css", "icon.svg", "logo/", "manifest-"}
    other = {p for p in rest if "theme/" not in p and "well-known" not in p}
    readers = {
        p for p in other if p.startswith(("api/v1/auth/", "api/v1/me", "api/v1/engagement/", "api/v1/push/"))
    }
    assert other - readers == {"health/live", "health/ready", "api/v1/site-config", "api/v1/app-config"}
    # Readers' own addresses (ADR-0050): each listed on purpose, each a ReaderView (bearer token, rate limit,
    # never cached unless the same for everyone). None of them reaches anything of the newsroom's.
    assert readers == {
        "api/v1/auth/methods",
        "api/v1/auth/code",
        "api/v1/auth/code/verify",
        "api/v1/auth/google",
        "api/v1/auth/apple",
        "api/v1/auth/refresh",
        "api/v1/auth/sign-out",
        "api/v1/me",
        "api/v1/me/export",
        "api/v1/me/<slug:what>",
        "api/v1/engagement/state",
        "api/v1/engagement/posts/<uuid:post_id>/like",
        "api/v1/engagement/posts/<uuid:post_id>/bookmark",
        "api/v1/engagement/posts/<uuid:post_id>/comments",
        "api/v1/engagement/posts/<uuid:post_id>/opened",
        "api/v1/engagement/posts/<uuid:post_id>/readers",
        "api/v1/engagement/comments/<uuid:comment_id>",
        "api/v1/engagement/comments/<uuid:comment_id>/like",
        "api/v1/engagement/follows/<slug:kind>/<uuid:target>",
        "api/v1/push/key",
        "api/v1/push/subscriptions",
    }
    from newsplatform.accounts.reader_api import ReaderView

    for p in patterns:
        if str(p.pattern) in readers:
            assert issubclass(p.callback.view_class, ReaderView), p.pattern
    assert content == {
        "home",
        "latest",
        "types/<slug:kind>",
        "categories/<slug:slug>",
        "tags/<slug:slug>",
        "stories/<slug:slug>",
        "authors/<slug:slug>",
        "articles/<slug:slug>",
        "articles/<slug:slug>/related",
        "navigation",
        "search",
        "search/suggest",
        "resolve",
        # M2: the publisher's own pages and the sitemaps the website serves.
        "pages",
        "pages/<slug:key>",
        "sitemap",
        "sitemap/news",
        "sitemap/<slug:month>",
    }
    for p in patterns:
        if "/content/" in str(p.pattern):
            assert issubclass(p.callback.view_class, PublicView)


@pytest.mark.django_db
def test_list_endpoints_have_constant_query_counts(admin_api, django_assert_max_num_queries, make_staff):
    _, a = admin_api()
    for _ in range(12):
        make_staff("journalist")
    for path in ("staff", "roles", "audit", "logs/auth", "approvals", "integrations"):
        with django_assert_max_num_queries(10):
            assert a.get(path).status_code == 200


@pytest.mark.django_db
def test_security_headers(api):
    res = api.get("auth/session")
    assert res["Content-Security-Policy"].startswith("default-src 'none'")
    assert res["X-Frame-Options"] == "DENY" and res["Cache-Control"] == "no-store"
    assert res["X-Content-Type-Options"] == "nosniff" and res["Referrer-Policy"] == "no-referrer"
    assert res["Content-Type"] == "application/problem+json"


@pytest.mark.django_db
def test_audit_export_is_audited_and_neutralises_formulas(admin_api):
    from newsplatform.audit.models import AuditEntry

    _, a = admin_api()
    a.post("staff/invites", {"email": "a@example.test", "grants": [{"role": "journalist"}]})
    body = b"".join(a.post("audit/export").streaming_content).decode()
    assert "staff.invited" in body and AuditEntry.objects.filter(action="audit.exported").exists()
    from newsplatform.audit.api import _safe

    assert _safe("=HYPERLINK(1)") == "'=HYPERLINK(1)" and _safe("ok") == "ok"
    assert a.post("audit/verify").json()["ok"] is True


@pytest.mark.parametrize(
    "addr",
    [
        "127.0.0.1",
        "10.1.2.3",
        "169.254.169.254",
        "192.168.0.1",
        "172.16.0.1",
        "0.0.0.0",
        "100.64.0.1",
        "::1",
        "fd00::1",
        "fe80::1",
        "::ffff:169.254.169.254",
        "64:ff9b::a9fe:a9fe",
        "2002:a9fe:a9fe::1",
        "224.0.0.1",
    ],
)
def test_ssrf_private_addresses(addr, monkeypatch):
    assert not http.is_public_address(addr)
    family = socket.AF_INET6 if ":" in addr else socket.AF_INET
    monkeypatch.setattr(socket, "getaddrinfo", lambda *a, **k: [(family, 1, 6, "", (addr, 443))])
    with pytest.raises(http.UnsafeDestination):
        http.fetch("GET", "https://innocent.example/")


def test_ssrf_one_bad_address_among_good_ones(monkeypatch):
    monkeypatch.setattr(
        socket,
        "getaddrinfo",
        lambda *a, **k: [(2, 1, 6, "", ("8.8.8.8", 443)), (2, 1, 6, "", ("10.0.0.1", 443))],
    )
    with pytest.raises(http.UnsafeDestination):
        http.fetch("GET", "https://mixed.example/")


@pytest.mark.parametrize(
    "url",
    [
        "http://example.com/",
        "https://u:p@example.com/",
        "https://example.com:8443/",
        "file:///etc/passwd",
        "https://[::1]/",
        "https://127.0.0.1/",
        "https://2130706433/",
    ],
)
def test_ssrf_url_shapes(url):
    with pytest.raises(http.UnsafeDestination):
        http.fetch("GET", url)


@pytest.mark.parametrize(
    ("hops", "xff", "expected"),
    [
        (0, "1.1.1.1", "9.9.9.9"),
        (1, "1.1.1.1, 2.2.2.2", "2.2.2.2"),
        (2, "evil, 1.1.1.1, 2.2.2.2", "1.1.1.1"),
        (2, "2.2.2.2", "9.9.9.9"),
        (1, "garbage", None),
    ],
)
def test_client_ip_cannot_be_spoofed(settings, hops, xff, expected):
    settings.TRUSTED_PROXY_HOPS = hops
    assert client_ip(RequestFactory().get("/", REMOTE_ADDR="9.9.9.9", HTTP_X_FORWARDED_FOR=xff)) == expected


def test_redaction():
    out = str(
        redact(
            {
                "password": "p",
                "nested": {"access_token": "t", "x": ["+255712345678", "a@b.co"]},
                "auth": "Bearer abc.def",
                "key": "AKIAIOSFODNN7EXAMPLE",
            }
        )
    )
    for leak in ("'p'", "'t'", "+255712345678", "a@b.co", "abc.def", "AKIAIOSFODNN7EXAMPLE"):
        assert leak not in out
    assert redact_text("order 12345") == "order 12345"


def test_rate_limit_exact():
    for _ in range(5):
        check("t", "s", Limit(5, 60), fail_closed=True)
    with pytest.raises(RateLimited) as e:
        check("t", "s", Limit(5, 60), fail_closed=True)
    assert 1 <= e.value.retry_after <= 60
    check("t", "other", Limit(5, 60), fail_closed=True)


def test_deployed_checks_refuse_unsafe_settings(settings):
    from newsplatform.staff_security.checks import deployed_environment_is_hardened as chk

    settings.IS_DEPLOYED = True
    ids = {e.id for e in chk(None)}
    assert {"staff_security.E002", "staff_security.E003", "staff_security.E005"} <= ids


@pytest.mark.django_db
def test_user_constraints():
    from django.db import IntegrityError, transaction

    from newsplatform.accounts.models import User

    User.objects.create_user(email="A@x.co", display_name="a")
    for bad in ({"email": "a@X.co"}, {"phone": "0712"}, {}):
        with pytest.raises(IntegrityError), transaction.atomic():
            User(display_name="b", password="!", **bad).save()
