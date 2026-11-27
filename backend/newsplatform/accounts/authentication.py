from django.core.cache import cache as local
from rest_framework.authentication import BaseAuthentication
from rest_framework.request import Request

from newsplatform.accounts import tokens
from newsplatform.accounts.models import User


class ReaderAuthentication(BaseAuthentication):
    """`Authorization: Bearer <access>`. A family revoked (signed out, reused) ends its access tokens too."""

    def authenticate(self, request: Request) -> tuple[User, str] | None:
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return None
        user_id, family = tokens.read_access(header[7:].strip())
        key = f"family-alive:{family}"
        alive = local.get(key)
        if alive is None:
            alive = tokens.family_alive(family)
            local.set(key, alive, 30)
        if not alive:
            raise tokens.Unauthenticated("Sign in again.")
        user = User.objects.filter(pk=user_id).first()
        if user is None or not user.can_sign_in:
            raise tokens.Unauthenticated("Sign in again.")
        return user, family

    def authenticate_header(self, request: Request) -> str:
        return 'Bearer realm="readers"'
