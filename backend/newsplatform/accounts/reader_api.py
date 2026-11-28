"""Readers' own endpoints (ADR-0050): signing in, their account, and what they do. Never cached by anyone."""

import hashlib
import hmac
from typing import Any, ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from newsplatform.accounts import reader_shapes as shapes
from newsplatform.accounts import signin, tokens
from newsplatform.accounts.authentication import ReaderAuthentication
from newsplatform.accounts.models import Identity, User
from newsplatform.common.errors import DomainError
from newsplatform.common.middleware import client_ip, resolve_ip
from newsplatform.common.ratelimit import Limit, check, subject_key
from newsplatform.rbac.permissions import PublicEndpoint

PRIVATE = {"Cache-Control": "no-store", "Vary": "Authorization"}


class ReaderView(APIView):
    authentication_classes = [ReaderAuthentication]
    permission_classes = [PublicEndpoint]
    needs_reader: ClassVar[bool] = True
    limit: ClassVar[Limit] = Limit(120, 60)

    def initial(self, request: Request, *args: Any, **kwargs: Any) -> None:
        super().initial(request, *args, **kwargs)
        user = reader_or_none(request)
        who = str(user.pk) if user else (self.ip(request) or "-")
        check(f"reader:{type(self).__name__}", subject_key(who), self.limit, fail_closed=False)
        if self.needs_reader and user is None:
            raise tokens.Unauthenticated("Sign in to do this.")

    @staticmethod
    def ip(request: Request) -> str | None:
        """The reader's address. Through the website's server it comes signed with the website's secret,
        so the limits on SMS codes count readers, not the website; an unsigned or wrongly signed one is
        ignored."""
        told, mac = request.headers.get("X-Reader-Ip", ""), request.headers.get("X-Reader-Ip-Mac", "")
        if told and mac:
            from newsplatform.integrations.providers.web import WebConfig
            from newsplatform.integrations.services import get_active

            web = get_active("web", WebConfig)
            if web is not None:
                expected = hmac.new(
                    web.secret.get_secret_value().encode(), f"reader-ip:{told}".encode(), hashlib.sha256
                ).hexdigest()
                if hmac.compare_digest(expected, mac):
                    return resolve_ip(told, "")
        return client_ip(request._request)

    @staticmethod
    def device(request: Request) -> str:
        return str(body(request).get("device") or request.headers.get("User-Agent", ""))[:120]

    def handle_exception(self, exc: Exception) -> Response:
        response: Response = super().handle_exception(exc)
        for k, v in PRIVATE.items():
            response[k] = v
        return response


def body(request: Request) -> dict[str, Any]:
    data = request.data
    return dict(data) if isinstance(data, dict) else {}


def reader(request: Request) -> User:
    """The signed-in reader; ReaderView has already refused everyone else where one is needed."""
    if not isinstance(request.user, User):
        raise tokens.Unauthenticated("Sign in to do this.")
    return request.user


def reader_or_none(request: Request) -> User | None:
    return request.user if isinstance(request.user, User) else None


def private(data: Any, status: int = 200) -> Response:
    return Response(data, status=status, headers=PRIVATE)


def me(user: User) -> dict[str, Any]:
    providers = sorted(set(Identity.objects.filter(user=user).values_list("provider", flat=True)))
    return {
        "id": str(user.pk),
        "display_name": user.display_name,
        "username": user.username or "",
        "initial": (user.display_name or user.username or "?")[:1].upper(),
        "phone": user.phone or "",
        "email": user.email or "",
        "locale": user.locale,
        "methods": providers,
        "onboarding": signin.needs_onboarding(user),
        "hide_from_readers": user.hide_from_readers,
        "bio": user.bio,
        # What to show in the form: the reader's own, else the one a provider verified.
        "contact_email": user.contact_email or user.email or "",
        "joined": user.created_at.date().isoformat(),
    }


def signed_in(done: signin.SignedIn) -> Response:
    return private({**done.pair.as_dict(), "created": done.created, "user": me(done.user)})


class MethodsView(ReaderView):
    needs_reader = False
    authentication_classes = []

    @extend_schema(operation_id="auth_methods", responses=shapes.MethodsSerializer)
    def get(self, request: Request) -> Response:
        data = signin.methods()
        # Which ways are open changes rarely: a CDN may keep it a minute.
        return Response(data, headers={"Cache-Control": "public, max-age=60, s-maxage=60"})


class CodeRequestView(ReaderView):
    needs_reader = False
    authentication_classes = []
    limit = Limit(10, 60)

    @extend_schema(
        operation_id="auth_code",
        request=shapes.CodeRequestSerializer,
        responses={201: shapes.CodeSentSerializer},
    )
    def post(self, request: Request) -> Response:
        sent = signin.request_code(
            str(body(request).get("phone", "")),
            ip=self.ip(request) or "0.0.0.0",  # noqa: S104 (a subject for the limiter, not a socket)
            locale="en" if body(request).get("locale") == "en" else "sw",
        )
        answer: dict[str, Any] = {
            "challenge": str(sent.challenge),
            "phone": sent.phone,
            "resend_in": sent.resend_in,
            "expires_in": sent.expires_in,
        }
        if sent.local_code:
            answer["local_code"] = sent.local_code  # LOCAL_SMS only, refused in deployed environments
        return private(answer, 201)


class CodeVerifyView(ReaderView):
    needs_reader = False
    authentication_classes = []
    limit = Limit(20, 60)

    @extend_schema(
        operation_id="auth_code_verify",
        request=shapes.CodeVerifySerializer,
        responses=shapes.SignedInSerializer,
    )
    def post(self, request: Request) -> Response:
        done = signin.with_phone(
            str(body(request).get("challenge", "")),
            str(body(request).get("code", "")),
            device=self.device(request),
            ip=self.ip(request),
        )
        return signed_in(done)


class GoogleView(ReaderView):
    needs_reader = False
    authentication_classes = []
    limit = Limit(20, 60)

    @extend_schema(
        operation_id="auth_google",
        request=shapes.ProviderSignInSerializer,
        responses=shapes.SignedInSerializer,
    )
    def post(self, request: Request) -> Response:
        d = body(request)
        return signed_in(
            signin.with_google(
                id_token=str(d.get("id_token", "")),
                code=str(d.get("code", "")),
                redirect_uri=str(d.get("redirect_uri", "")),
                verifier=str(d.get("code_verifier", "")),
                nonce=str(d["nonce"]) if d.get("nonce") else None,
                device=self.device(request),
                ip=self.ip(request),
            )
        )


class AppleView(ReaderView):
    needs_reader = False
    authentication_classes = []
    limit = Limit(20, 60)

    @extend_schema(
        operation_id="auth_apple",
        request=shapes.ProviderSignInSerializer,
        responses=shapes.SignedInSerializer,
    )
    def post(self, request: Request) -> Response:
        d = body(request)
        return signed_in(
            signin.with_apple(
                id_token=str(d.get("id_token", "")),
                code=str(d.get("code", "")),
                redirect_uri=str(d.get("redirect_uri", "")),
                name=str(d.get("name", ""))[:80],
                nonce=str(d["nonce"]) if d.get("nonce") else None,
                device=self.device(request),
                ip=self.ip(request),
            )
        )


class RefreshView(ReaderView):
    needs_reader = False
    authentication_classes = []
    limit = Limit(30, 60)

    @extend_schema(
        operation_id="auth_refresh", request=shapes.RefreshSerializer, responses=shapes.SignedInSerializer
    )
    def post(self, request: Request) -> Response:
        user, pair = tokens.rotate(
            str(body(request).get("refresh", "")), device=self.device(request), ip=self.ip(request)
        )
        return private({**pair.as_dict(), "user": me(user)})


class SignOutView(ReaderView):
    needs_reader = False
    authentication_classes = []

    @extend_schema(operation_id="auth_sign_out", request=shapes.RefreshSerializer, responses={204: None})
    def post(self, request: Request) -> Response:
        tokens.revoke(str(body(request).get("refresh", "")))
        return private(None, 204)


class MeView(ReaderView):
    @extend_schema(operation_id="me", responses=shapes.ReaderSerializer)
    def get(self, request: Request) -> Response:
        return private(me(reader(request)))

    @extend_schema(
        operation_id="me_update", request=shapes.ProfileSerializer, responses=shapes.ReaderSerializer
    )
    def patch(self, request: Request) -> Response:
        return private(me(signin.update_profile(reader(request), body(request))))

    @extend_schema(
        operation_id="me_delete", request=shapes.DeleteSerializer, responses={202: shapes.DeletionSerializer}
    )
    def delete(self, request: Request) -> Response:
        if body(request).get("confirm") != "delete":
            raise DomainError("Confirm the deletion.", code="confirmation_required")
        signin.request_deletion(reader(request))
        return private({"grace_days": signin.GRACE_DAYS}, 202)


class ExportView(ReaderView):
    """Everything kept about the reader, as JSON (PDPA Tanzania 2022)."""

    limit = Limit(3, 3600)

    @extend_schema(operation_id="me_export", responses=shapes.ExportSerializer)
    def get(self, request: Request) -> Response:
        from newsplatform.engagement.models import Bookmark, Comment, Follow, Like

        user = reader(request)
        data = {
            "account": me(user),
            "identities": list(Identity.objects.filter(user=user).values("provider", "email", "created_at")),
            "consents": list(user.consents.values("kind", "version", "created_at")),
            "likes": list(Like.objects.filter(user=user).values("post_id", "created_at")),
            "bookmarks": list(Bookmark.objects.filter(user=user).values("post_id", "created_at")),
            "comments": list(
                Comment.objects.filter(user=user).values("post_id", "body", "status", "created_at")
            ),
            "follows": list(Follow.objects.filter(user=user).values("kind", "target", "created_at")),
        }
        return Response(
            data,
            headers={**PRIVATE, "Content-Disposition": 'attachment; filename="my-data.json"'},
        )
