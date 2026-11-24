from typing import Any, ClassVar

from django.conf import settings
from django.db import transaction
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.exceptions import NotAuthenticated
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.api import AnonymousStaffView, StaffView, body, schema
from newsplatform.common.errors import Conflict, NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.common.ratelimit import Limit, check
from newsplatform.rbac.selectors import grants_for
from newsplatform.site_config.services import brand_name
from newsplatform.staff_security import login, mfa, sessions, staff
from newsplatform.staff_security.authentication import session_of
from newsplatform.staff_security.events import auth_event
from newsplatform.staff_security.models import (
    AuthEvent,
    Passkey,
    SessionStage,
    StaffSession,
    StaffToken,
    TokenKind,
    TotpDevice,
)


# ---- serializers ----------------------------------------------------------------------------------------
class SessionInfoSerializer(serializers.Serializer[Any]):
    stage = serializers.ChoiceField(choices=SessionStage.choices)
    brand_name = serializers.CharField()
    csrf_token = serializers.CharField()
    mfa_methods = serializers.ListField(child=serializers.CharField())
    user = schema(
        "SessionUser",
        id=serializers.UUIDField(),
        display_name=serializers.CharField(),
        email=serializers.EmailField(),
        locale=serializers.CharField(),
    )
    permissions = serializers.ListField(child=serializers.CharField())
    expires_at = serializers.DateTimeField()


class LoginSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)
    password = serializers.CharField(max_length=256, trim_whitespace=False)


class CodeSerializer(serializers.Serializer[Any]):
    code = serializers.CharField(max_length=20)


class CredentialSerializer(serializers.Serializer[Any]):
    credential = serializers.DictField()
    name = serializers.CharField(max_length=60, allow_blank=True, default="")


class AcceptSerializer(serializers.Serializer[Any]):
    token = serializers.CharField(max_length=100)
    display_name = serializers.CharField(max_length=80)
    password = serializers.CharField(max_length=256, trim_whitespace=False)
    locale = serializers.ChoiceField(choices=["sw", "en"], default="sw")


class ResetSerializer(serializers.Serializer[Any]):
    token = serializers.CharField(max_length=100)
    password = serializers.CharField(max_length=256, trim_whitespace=False)


class PasswordSerializer(serializers.Serializer[Any]):
    current = serializers.CharField(max_length=256, trim_whitespace=False)
    new = serializers.CharField(max_length=256, trim_whitespace=False)


class EnrolResultSerializer(serializers.Serializer[Any]):
    session = SessionInfoSerializer()
    recovery_codes = serializers.ListField(child=serializers.CharField())


class StaffSessionSerializer(serializers.ModelSerializer[StaffSession]):
    current = serializers.SerializerMethodField()

    class Meta:
        model = StaffSession
        fields = [
            "id",
            "device_label",
            "ip",
            "country",
            "mfa_method",
            "created_at",
            "last_seen_at",
            "current",
        ]

    def get_current(self, obj: StaffSession) -> bool:
        return bool(obj.pk == self.context.get("current"))


class PasskeySerializer(serializers.ModelSerializer[Passkey]):
    class Meta:
        model = Passkey
        fields = ["id", "name", "backed_up", "created_at", "last_used_at"]


class AuthEventSerializer(serializers.ModelSerializer[AuthEvent]):
    user_name = serializers.CharField(source="user.display_name", default="", read_only=True)

    class Meta:
        model = AuthEvent
        fields = [
            "id",
            "kind",
            "ok",
            "user",
            "user_name",
            "ip",
            "country",
            "user_agent",
            "detail",
            "created_at",
        ]


class SecurityOverviewSerializer(serializers.Serializer[Any]):
    passkeys = PasskeySerializer(many=True)
    totp = serializers.BooleanField()
    recovery_codes_left = serializers.IntegerField()
    sessions = StaffSessionSerializer(many=True)
    recent_events = AuthEventSerializer(many=True)


class StaffMemberSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    display_name = serializers.CharField()
    email = serializers.EmailField()
    status = serializers.CharField()
    mfa = serializers.SerializerMethodField()
    roles = serializers.SerializerMethodField()

    def get_mfa(self, obj: Any) -> bool:
        return bool(obj.has_mfa)

    def get_roles(self, obj: Any) -> list[dict[str, str]]:
        return [
            {
                "assignment": str(a.pk),
                "key": a.role.key,
                "name_en": a.role.name_en,
                "name_sw": a.role.name_sw,
                "scope_type": a.scope_type,
                "scope_id": a.scope_id,
            }
            for a in obj.assignments.all()
        ]


class InviteRowSerializer(serializers.ModelSerializer[StaffToken]):
    class Meta:
        model = StaffToken
        fields = ["id", "email", "grants", "expires_at", "created_at"]


class GrantSerializer(serializers.Serializer[Any]):
    role = serializers.SlugField()
    scope_type = serializers.CharField(default="", allow_blank=True)
    scope_id = serializers.CharField(default="", allow_blank=True)


class InviteSerializer(serializers.Serializer[Any]):
    email = serializers.EmailField(max_length=254)
    grants = GrantSerializer(many=True, allow_empty=False)


class LinkResultSerializer(serializers.Serializer[Any]):
    approval_required = serializers.BooleanField()
    emailed = serializers.BooleanField()
    link = serializers.CharField(allow_null=True)


# ---- helpers --------------------------------------------------------------------------------------------
def _info(session: StaffSession, token: str) -> dict[str, Any]:
    user = session.user
    active = session.is_active_stage
    return {
        "stage": session.stage,
        "brand_name": brand_name(),
        "csrf_token": sessions.csrf_for(token),
        "mfa_methods": mfa.methods(user),
        "user": {
            "id": user.pk,
            "display_name": user.display_name,
            "email": user.email,
            "locale": user.locale,
        },
        "permissions": sorted(grants_for(user).any) if active else [],
        "expires_at": session.expires_at,
    }


def _with_cookie(response: Response, session: StaffSession, token: str) -> Response:
    response.set_cookie(
        settings.STAFF_COOKIE_NAME,
        token,
        expires=session.expires_at,
        path="/",
        httponly=True,
        secure=settings.STAFF_COOKIE_SECURE,
        samesite="Strict",
    )
    return response


def _token(request: Request) -> str:
    return request.COOKIES[settings.STAFF_COOKIE_NAME]


class AnyStageView(StaffView):
    """Any live session, including before MFA. Each view states which stages it accepts."""

    class HasSession(BasePermission):
        def has_permission(self, request: Request, view: Any) -> bool:
            if request.auth is None:
                raise NotAuthenticated
            return session_of(request).stage in view.stages

    permission_classes = [HasSession]
    stages: ClassVar[set[str]] = set(SessionStage.values)


class EnrolView(AnyStageView):
    """First enrolment, or adding a factor later; the latter needs a fresh MFA check."""

    stages: ClassVar[set[str]] = {SessionStage.MFA_ENROLL, SessionStage.ACTIVE}

    def check_permissions(self, request: Request) -> None:
        super().check_permissions(request)
        if session_of(request).stage == SessionStage.MFA_ENROLL:
            # An account that has MFA must never reach enrolment through a half-open session.
            if login.has_mfa(session_of(request).user):
                raise Conflict("Multi-factor sign-in is already set up. Sign in again.", code="mfa_exists")
        elif not session_of(request).has_recent_mfa():
            from newsplatform.common.errors import StepUpRequired

            raise StepUpRequired("Confirm it's you to continue.")

    def finish(self, request: Request, method: str, codes: list[str]) -> Response:
        session = session_of(request)
        token = login.complete(session, method) if not session.is_active_stage else _token(request)
        return _with_cookie(
            Response({"session": _info(session, token), "recovery_codes": codes}), session, token
        )


# ---- sign-in --------------------------------------------------------------------------------------------
class LoginView(AnonymousStaffView):
    @extend_schema(operation_id="auth_login", request=LoginSerializer, responses=SessionInfoSerializer)
    def post(self, request: Request) -> Response:
        data = LoginSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        session, token = login.password_login(**data.validated_data, request=request._request)
        return _with_cookie(Response(_info(session, token)), session, token)


class SessionView(AnyStageView):
    @extend_schema(operation_id="auth_session", responses=SessionInfoSerializer)
    def get(self, request: Request) -> Response:
        return Response(_info(session_of(request), _token(request)))

    @extend_schema(operation_id="auth_logout", responses={204: None})
    def delete(self, request: Request) -> Response:
        sessions.revoke(session_of(request), "logout")
        auth_event("logout", ok=True, user=session_of(request).user)
        response = Response(status=204)
        response.delete_cookie(settings.STAFF_COOKIE_NAME, path="/", samesite="Strict")
        return response


class MfaVerifyView(AnyStageView):
    """The same check completes sign-in (mfa_challenge) or refreshes it for step-up (active)."""

    stages: ClassVar[set[str]] = {SessionStage.MFA_CHALLENGE, SessionStage.ACTIVE}

    def done(self, request: Request, method: str) -> Response:
        session = session_of(request)
        if session.is_active_stage:
            sessions.refresh_mfa(session, method)
            auth_event("step_up", ok=True, user=session.user, detail=method)
            return Response(_info(session, _token(request)))
        token = login.complete(session, method)
        return _with_cookie(Response(_info(session, token)), session, token)


class TotpVerifyView(MfaVerifyView):
    @extend_schema(operation_id="mfa_totp_verify", request=CodeSerializer, responses=SessionInfoSerializer)
    def post(self, request: Request) -> Response:
        data = CodeSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        mfa.totp_verify(session_of(request), data.validated_data["code"])
        return self.done(request, "totp")


class RecoveryVerifyView(MfaVerifyView):
    @extend_schema(
        operation_id="mfa_recovery_verify", request=CodeSerializer, responses=SessionInfoSerializer
    )
    def post(self, request: Request) -> Response:
        data = CodeSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        mfa.recovery_verify(session_of(request), data.validated_data["code"])
        return self.done(request, "recovery")


class PasskeyAuthOptionsView(AnyStageView):
    stages: ClassVar[set[str]] = {SessionStage.MFA_CHALLENGE, SessionStage.ACTIVE}

    @extend_schema(operation_id="mfa_passkey_options", request=None, responses=OpenApiTypes.OBJECT)
    def post(self, request: Request) -> Response:
        return Response(mfa.passkey_auth_options(session_of(request)))


class PasskeyAuthView(MfaVerifyView):
    @extend_schema(
        operation_id="mfa_passkey_verify", request=CredentialSerializer, responses=SessionInfoSerializer
    )
    def post(self, request: Request) -> Response:
        data = CredentialSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        mfa.passkey_verify(session_of(request), data.validated_data["credential"])
        return self.done(request, "passkey")


# ---- enrolment ------------------------------------------------------------------------------------------
class PasskeyRegisterOptionsView(EnrolView):
    @extend_schema(operation_id="mfa_passkey_register_options", request=None, responses=OpenApiTypes.OBJECT)
    def post(self, request: Request) -> Response:
        return Response(mfa.passkey_register_options(session_of(request)))


class PasskeyRegisterView(EnrolView):
    @extend_schema(
        operation_id="mfa_passkey_register", request=CredentialSerializer, responses=EnrolResultSerializer
    )
    def post(self, request: Request) -> Response:
        data = CredentialSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        codes = mfa.passkey_register(session_of(request), **data.validated_data)
        return self.finish(request, "passkey", codes)


class TotpBeginView(EnrolView):
    @extend_schema(
        operation_id="mfa_totp_begin",
        request=None,
        responses=schema("TotpBegin", secret=serializers.CharField(), qr_svg=serializers.CharField()),
    )
    def post(self, request: Request) -> Response:
        return Response(mfa.totp_begin(session_of(request)))


class TotpConfirmView(EnrolView):
    @extend_schema(operation_id="mfa_totp_confirm", request=CodeSerializer, responses=EnrolResultSerializer)
    def post(self, request: Request) -> Response:
        data = CodeSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        codes = mfa.totp_confirm(session_of(request), data.validated_data["code"])
        return self.finish(request, "totp", codes)


# ---- invitations and resets -----------------------------------------------------------------------------
class AcceptInviteView(AnonymousStaffView):
    limit: ClassVar[Limit] = Limit(10, 60)

    @extend_schema(
        operation_id="auth_accept_invite", request=AcceptSerializer, responses=SessionInfoSerializer
    )
    def post(self, request: Request) -> Response:
        data = AcceptSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        user = staff.accept_invite(
            raw=d["token"], display_name=d["display_name"], password=d["password"], locale=d["locale"]
        )
        stage = SessionStage.MFA_CHALLENGE if login.has_mfa(user) else SessionStage.MFA_ENROLL
        session, token = sessions.create(user, stage, request._request)
        return _with_cookie(Response(_info(session, token)), session, token)


class CompleteResetView(AnonymousStaffView):
    limit: ClassVar[Limit] = Limit(10, 60)

    @extend_schema(operation_id="auth_complete_reset", request=ResetSerializer, responses={204: None})
    def post(self, request: Request) -> Response:
        data = ResetSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        staff.complete_reset(raw=data.validated_data["token"], password=data.validated_data["password"])
        return Response(status=204)


# ---- my security ----------------------------------------------------------------------------------------
class MySecurityView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": None}

    @extend_schema(operation_id="me_security", responses=SecurityOverviewSerializer)
    def get(self, request: Request) -> Response:
        user, now = session_of(request).user, session_of(request)
        live = StaffSession.objects.filter(
            user=user, revoked_at__isnull=True, stage=SessionStage.ACTIVE, expires_at__gt=_now()
        ).order_by("-last_seen_at")
        return Response(
            SecurityOverviewSerializer(
                {
                    "passkeys": user.passkeys.order_by("id"),
                    "totp": TotpDevice.objects.filter(user=user, confirmed_at__isnull=False).exists(),
                    "recovery_codes_left": user.recovery_codes.filter(used_at__isnull=True).count(),
                    "sessions": live,
                    "recent_events": AuthEvent.objects.filter(user=user)
                    .select_related("user")
                    .order_by("-id")[:20],
                },
                context={"current": now.pk},
            ).data
        )


def _now() -> Any:
    from django.utils import timezone

    return timezone.now()


class PasswordView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": None}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(operation_id="me_password", request=PasswordSerializer, responses={204: None})
    def post(self, request: Request) -> Response:
        data = PasswordSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        check("password-change", str(request.user.pk), Limit(5, 600), fail_closed=True)
        staff.change_password(session=session_of(request), **data.validated_data)
        return Response(status=204)


class RecoveryCodesView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": None}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(
        operation_id="me_recovery_codes",
        request=None,
        responses=schema(
            "RecoveryCodes", recovery_codes=serializers.ListField(child=serializers.CharField())
        ),
    )
    def post(self, request: Request) -> Response:
        return Response({"recovery_codes": mfa.generate_recovery_codes(session_of(request).user)})


class FactorView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"DELETE": None}
    step_up: ClassVar[tuple[str, ...]] = ("DELETE",)

    @extend_schema(
        operation_id="me_factor_remove",
        responses={204: None},
        parameters=[
            OpenApiParameter("factor", str, OpenApiParameter.PATH, description="'totp' or a passkey id")
        ],
    )
    def delete(self, request: Request, factor: str) -> Response:
        mfa.remove_factor(session_of(request), passkey_id=None if factor == "totp" else factor)
        return Response(status=204)


class MySessionView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"DELETE": None}

    @extend_schema(operation_id="me_session_revoke", responses={204: None})
    def delete(self, request: Request, session_id: Any) -> Response:
        target = StaffSession.objects.filter(pk=session_id, user=session_of(request).user).first()
        if target is None:
            raise NotFound("Not found")
        sessions.revoke(target, "revoked_by_user")
        auth_event("session_revoked", ok=True, user=session_of(request).user)
        return Response(status=204)


# ---- staff management -----------------------------------------------------------------------------------
def _staff_qs() -> Any:
    from django.db.models import Exists, OuterRef, Q

    return (
        User.objects.filter(is_staff_member=True)
        .annotate(
            has_mfa=Q(Exists(Passkey.objects.filter(user=OuterRef("pk"))))
            | Q(Exists(TotpDevice.objects.filter(user=OuterRef("pk"), confirmed_at__isnull=False)))
        )
        .prefetch_related("assignments__role")
    )


def _member(user_id: Any) -> User:
    user: User | None = _staff_qs().filter(pk=user_id).first()
    if user is None:
        raise NotFound("Not found")
    return user


def _link_result(result: dict[str, Any]) -> Response:
    return Response(
        {
            "approval_required": result["approval"] is not None,
            "emailed": result["emailed"],
            "link": result["link"],
        },
        status=202 if result["approval"] else 201,
    )


class StaffListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "staff.view"}

    @extend_schema(
        operation_id="staff_list",
        responses=schema(
            "StaffList", staff=StaffMemberSerializer(many=True), invites=InviteRowSerializer(many=True)
        ),
    )
    def get(self, request: Request) -> Response:
        invites = StaffToken.objects.filter(
            kind=TokenKind.INVITE, used_at__isnull=True, revoked_at__isnull=True, expires_at__gt=_now()
        ).order_by("-id")
        return Response(
            {
                "staff": StaffMemberSerializer(_staff_qs().order_by("display_name"), many=True).data,
                "invites": InviteRowSerializer(invites, many=True).data,
            }
        )


class StaffInviteView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "staff.invite"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(
        operation_id="staff_invite",
        request=InviteSerializer,
        responses={201: LinkResultSerializer, 202: LinkResultSerializer},
    )
    def post(self, request: Request) -> Response:
        data = InviteSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        grants = [dict(g) for g in data.validated_data["grants"]]
        return _link_result(
            staff.invite(actor=session_of(request).user, email=data.validated_data["email"], grants=grants)
        )


class StaffInviteItemView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"DELETE": "staff.invite"}

    @extend_schema(operation_id="staff_invite_revoke", responses={204: None})
    def delete(self, request: Request, invite_id: Any) -> Response:
        with transaction.atomic():
            token = StaffToken.objects.select_for_update().filter(pk=invite_id, kind=TokenKind.INVITE).first()
            if token is None or not token.is_usable:
                raise NotFound("Not found")
            token.revoked_at = _now()
            token.save()
            record(
                actor=session_of(request).user, action="staff.invite_revoked", target=token, label=token.email
            )
        return Response(status=204)


class StaffResetView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "staff.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(
        operation_id="staff_reset",
        request=schema("StaffReset", reset_mfa=serializers.BooleanField()),
        responses={201: LinkResultSerializer, 202: LinkResultSerializer},
    )
    def post(self, request: Request, user_id: Any) -> Response:
        flag = serializers.BooleanField().run_validation(body(request).get("reset_mfa", False))
        return _link_result(
            staff.issue_reset(actor=session_of(request).user, user=_member(user_id), reset_mfa=flag)
        )


class StaffStatusView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "staff.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    class StaffStatus(serializers.Serializer[Any]):
        active = serializers.BooleanField()
        reason = serializers.CharField(max_length=500)

    @extend_schema(operation_id="staff_status", request=StaffStatus, responses={204: None})
    def post(self, request: Request, user_id: Any) -> Response:
        data = self.StaffStatus(data=request.data)
        data.is_valid(raise_exception=True)
        staff.set_status(actor=session_of(request).user, user=_member(user_id), **data.validated_data)
        return Response(status=204)


class StaffLogoutView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "staff.manage"}

    @extend_schema(operation_id="staff_force_logout", request=None, responses={204: None})
    def post(self, request: Request, user_id: Any) -> Response:
        user = _member(user_id)
        with transaction.atomic():
            count = sessions.revoke_all(user, "forced_logout")
            record(
                actor=session_of(request).user,
                action="staff.forced_logout",
                target=user,
                label=user.display_name,
                after={"sessions": count},
            )
        return Response(status=204)


class AuthEventListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "audit.view"}

    @extend_schema(
        operation_id="auth_events",
        responses=page_of(AuthEventSerializer),
        parameters=[
            OpenApiParameter("kind", str),
            OpenApiParameter("user", str),
            OpenApiParameter("cursor", str),
        ],
    )
    def get(self, request: Request) -> Response:
        rows = AuthEvent.objects.select_related("user")
        if kind := request.query_params.get("kind"):
            rows = rows.filter(kind=kind)
        if user := request.query_params.get("user"):
            rows = rows.filter(user_id=serializers.UUIDField().run_validation(user))
        page = TimeCursorPagination()
        return page.get_paginated_response(
            AuthEventSerializer(page.paginate_queryset(rows, request, view=self), many=True).data
        )
