import hmac
from typing import cast

from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.request import Request

from newsplatform.accounts.models import User
from newsplatform.common.errors import Forbidden
from newsplatform.staff_security import sessions
from newsplatform.staff_security.models import StaffSession


def session_of(request: Request) -> StaffSession:
    """The only place `request.auth` is narrowed to our session type."""
    return cast(StaffSession, request.auth)


_SAFE = {"GET", "HEAD", "OPTIONS"}


def check_origin(request: Request) -> None:
    """Browsers always send Origin on unsafe requests; anything else is refused."""
    if request.method not in _SAFE and request.headers.get("Origin") != settings.ADMIN_ORIGIN:
        raise Forbidden("Cross-site request refused.", code="csrf_failed")


class StaffSessionAuthentication(BaseAuthentication):
    def authenticate(self, request: Request) -> tuple[User, StaffSession] | None:
        check_origin(request)
        token = request.COOKIES.get(settings.STAFF_COOKIE_NAME)
        if not token:
            return None
        session = sessions.resolve(token, request._request)
        if session is None:
            return None
        if request.method not in _SAFE and not hmac.compare_digest(
            request.headers.get("X-CSRF-Token", "").encode(), sessions.csrf_for(token).encode()
        ):
            raise Forbidden("Security token mismatch. Reload the page.", code="csrf_failed")
        return session.user, session

    def authenticate_header(self, request: Request) -> str:
        return "Session"
