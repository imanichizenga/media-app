import ipaddress
import re
import uuid
from collections.abc import Callable

import structlog
from django.conf import settings
from django.http import HttpRequest, HttpResponse
from django.utils.crypto import constant_time_compare

from newsplatform.common import context

_RID = re.compile(r"^[A-Za-z0-9_-]{8,64}$")


def client_ip(request: HttpRequest) -> str | None:
    """Right-most-untrusted parsing: only the hops we operate may append to X-Forwarded-For."""
    hops: int = settings.TRUSTED_PROXY_HOPS
    raw = request.META.get("REMOTE_ADDR", "")
    if hops:
        chain = [p.strip() for p in request.META.get("HTTP_X_FORWARDED_FOR", "").split(",") if p.strip()]
        raw = chain[-hops] if len(chain) >= hops else raw
    try:
        ip = ipaddress.ip_address(raw)
    except ValueError:
        return None
    mapped = getattr(ip, "ipv4_mapped", None)
    return str(mapped or ip)


class RequestContextMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        given = request.headers.get("X-Request-ID", "")
        rid = given if _RID.match(given) else uuid.uuid4().hex
        # Geo headers count only when CloudFront proved itself with the shared origin secret.
        expected: str = settings.ORIGIN_VERIFY_SECRET
        trusted = bool(expected) and constant_time_compare(
            request.headers.get("X-Origin-Verify", ""), expected
        )
        country = request.headers.get("CloudFront-Viewer-Country", "")[:2] if trusted else ""
        context.set_context(
            context.RequestContext(
                rid, client_ip(request), request.headers.get("User-Agent", "")[:400], country
            )
        )
        structlog.contextvars.clear_contextvars()
        try:
            response = self.get_response(request)
        finally:
            context.set_context(None)
        response["X-Request-ID"] = rid
        return response


class SecurityHeadersMiddleware:
    """The API serves JSON only, so its CSP denies everything."""

    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        self.get_response = get_response

    def __call__(self, request: HttpRequest) -> HttpResponse:
        response = self.get_response(request)
        response.headers.setdefault("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")
        response.headers.setdefault("Permissions-Policy", "interest-cohort=()")
        response.headers.setdefault("Cross-Origin-Resource-Policy", "same-site")
        if settings.API_SURFACE == "admin":
            response.headers.setdefault("Cache-Control", "no-store")
        return response
